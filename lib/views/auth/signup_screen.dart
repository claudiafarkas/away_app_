// // lib/views/welcome/welcome_load.dart
// import 'package:flutter/material.dart';
// // call home page

// class SignUpPage extends StatelessWidget {
//   const SignUpPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color.fromARGB(255, 249, 248, 240),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 32),

//               // Away branding
//               const Center(
//                 child: Text(
//                   'Away.',
//                   style: TextStyle(
//                     fontSize: 42,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF062D40),
//                     fontFamily: 'Times New Roman',
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 48),
//               // Full Name
//               const TextField(
//                 decoration: InputDecoration(
//                   labelText: 'Full Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Email
//               // TODO: email verification checks
//               const TextField(
//                 decoration: InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Password
//               // TODO: pw verification checks
//               const TextField(
//                 obscureText: true,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               const TextField(
//                 obscureText: true,
//                 decoration: InputDecoration(
//                   labelText: 'Password Again',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Sign Up Button
//               ElevatedButton(
//                 onPressed: () {
//                   // TODO: implement sign-up logic
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF062D40),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//                 child: const Text('Create Account'),
//               ),

//               const SizedBox(height: 12),

//               // Back to Login
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Already have an account? Log in"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// lib/views/auth/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import './widgets/social_signin_button.dart';
import '../../widgets/bottom_nav_scaffold.dart';

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign up failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final auth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await _auth.signInWithCredential(cred);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google sign-up failed')));
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100), // Match signin screen padding
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

            // Form fields with consistent styling
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF062D40)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ...existing email field...
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
            // ...existing password fields...
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
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF062D40)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _signUpWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF062D40),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              SocialSignInButton(
                assetName: 'assets/google-logo.png',
                text: 'Continue with Google',
                onPressed: _isLoading ? () {} : () => _signUpWithGoogle(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(color: Color(0xFF062D40)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
