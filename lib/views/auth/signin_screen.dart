import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:away/views/auth/auth_flow.dart';
import 'package:away/views/auth/signup_screen.dart';
import 'package:away/views/auth/widgets/social_signin_button.dart';
import 'package:away/services/auth_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/theme/app_theme.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/soft_tile.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Sign In Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "We couldn't find an account with that email. Try signing up instead!";
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for help.';
      case 'invalid-credential':
        return "Email or password is incorrect. Please check and try again.";
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Sign in failed. Please check your credentials and try again.';
    }
  }

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        _showErrorDialog('Please enter both email and password.');
        return;
      }
      await FirebaseAuth.instance.signOut();
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (cred.user != null) {
        await AuthService.instance.saveUserToFirestore(cred.user!);
      }
      if (!mounted) return;
      await enterSignedInApp(context);
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(_getFriendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCred = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      if (userCred?.user != null) {
        await enterSignedInApp(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        'Google sign-in failed. Please try again and confirm Google is enabled for this app.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CloudBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 56),
                Text('Away.', style: AppTheme.wordmark),
                const SizedBox(height: 8),
                const Text(
                  'Collect places the way you’d pin them.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                SoftTile(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        ElevatedButton(
                          onPressed: _signInWithEmail,
                          child: const Text('Sign In'),
                        ),
                        if (Theme.of(context).platform ==
                            TargetPlatform.iOS) ...[
                          const SizedBox(height: 14),
                          SignInWithAppleButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () async {
                                      setState(() => _isLoading = true);
                                      try {
                                        final userCred =
                                            await AuthService.instance
                                                .signInWithApple();

                                        if (!mounted) return;

                                        if (userCred?.user != null) {
                                          await enterSignedInApp(context);
                                        } else {
                                          _showErrorDialog(
                                            'Apple sign-in cancelled. Please try again.',
                                          );
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        _showErrorDialog(
                                          "Apple sign-in failed. Please try again and confirm you're using the right credentials.",
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    },
                            style: SignInWithAppleButtonStyle.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SocialSignInButton(
                          assetName: 'assets/google-logo.png',
                          text: 'Continue with Google',
                          onPressed: _signInWithGoogle,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
