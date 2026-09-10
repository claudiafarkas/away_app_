import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:away/services/auth_service.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/theme/app_theme.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/soft_tile.dart';
import 'auth_flow.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead!';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Sign up is currently unavailable. Please try again later.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  Future<void> _signUpWithEmail() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pass != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();
      final user = _auth.currentUser;
      if (user != null) {
        await AuthService.instance.saveUserToFirestore(user);
      }
      if (!mounted) return;
      await enterSignedInApp(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getFriendlyErrorMessage(e)),
          backgroundColor: Colors.red.shade400,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
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
                const SizedBox(height: 40),
                Text('Away.', style: AppTheme.wordmark.copyWith(fontSize: 36)),
                const SizedBox(height: 8),
                const Text(
                  'Create a quieter place for your finds.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                SoftTile(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        )
                      else
                        ElevatedButton(
                          onPressed: _signUpWithEmail,
                          child: const Text('Create Account'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign in'),
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
