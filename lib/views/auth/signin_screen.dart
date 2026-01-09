// import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:away/views/auth/signup_screen.dart';
import 'package:away/widgets/bottom_nav_scaffold.dart';
import 'package:away/services/auth_service.dart';
// import 'package:away/views/auth/widgets/social_signin_button.dart';
// import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut(); // Clears any existing credentials
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Future<void> _signInWithGoogle() async {
  //   if (_isLoading) return;

  //   setState(() => _isLoading = true);
  //   try {
  //     print("📱 Starting Google sign in flow...");
  //     final userCred = await AuthService.instance.signInWithGoogle();

  //     if (!mounted) return;

  //     if (userCred?.user != null) {
  //       print("✅ Sign in successful, navigating...");
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
  //       );
  //     } else {
  //       print("⚠️ Sign in cancelled or failed");
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('Sign in cancelled')));
  //     }
  //   } catch (e) {
  //     print("❌ Sign in error: $e");
  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Sign in failed: ${e.toString()}')),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100), // Add top padding
            const Text(
              'Away.',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062D40),
                fontFamily: 'Times New Roman',
              ),
            ),
            const SizedBox(height: 40),

            // Email / Password fields
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF062D40)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF062D40)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign-in button or spinner
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF062D40),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 24),

              if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                const SizedBox(height: 16),
                SignInWithAppleButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            setState(() => _isLoading = true);
                            try {
                              final userCred =
                                  await AuthService.instance.signInWithApple();

                              if (!mounted) return;

                              if (userCred?.user != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BottomNavScaffold(),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Apple sign-in cancelled'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Apple sign-in failed: $e'),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                  style: SignInWithAppleButtonStyle.black,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Navigation to Sign-Up
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(color: Color(0xFF062D40)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
