// // lib/views/welcome/welcome_load.dart
// import 'package:flutter/material.dart';
// import '../auth/signup_screen.dart';
// import 'package:away/widgets/bottom_nav_scaffold.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package\:google\_sign\_in/google\_sign\_in.dart';

// final _auth = FirebaseAuth.instance;

// class AuthPage extends StatelessWidget {
//   const AuthPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color.fromARGB(255, 249, 248, 240),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Away.',
//               style: TextStyle(
//                 fontSize: 52,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF062D40),
//                 fontFamily: 'Times New Roman',
//               ),
//             ),
//             const SizedBox(height: 40), // spacing before form
//             // Login form
//             const TextField(decoration: InputDecoration(labelText: 'Email')),
//             const SizedBox(height: 12),
//             const TextField(
//               obscureText: true,
//               decoration: InputDecoration(labelText: 'Password'),
//             ),
//             const SizedBox(height: 24),

//             const Text("- or login with -"),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: () {
//                 // TODO handle login
//                 // temp button override to test
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
//                 );
//               },
//               child: const Text('Log in'),
//             ),
//             const SizedBox(height: 16),

//             TextButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const SignUpPage()),
//                 );
//               },
//               child: const Text("Don’t have an account? Sign up here"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// lib/views/auth/auth_screen.dart
// import 'package:flutter/material.dart';
// import 'signin_screen.dart';
// import 'signup_screen.dart';

// /// A wrapper screen that lets the user toggle between
// /// Sign In and Sign Up tabs.
// class AuthScreen extends StatelessWidget {
//   const AuthScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF9F8F0),
//         appBar: AppBar(
//           backgroundColor: const Color(0xFFF9F8F0),
//           elevation: 0,
//           bottom: TabBar(
//             indicatorColor: const Color(0xFF062D40),
//             labelColor: const Color(0xFF062D40),
//             unselectedLabelColor: Colors.grey,
//             tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
//           ),
//         ),
//         body: const TabBarView(children: [SignInScreen(), SignUpScreen()]),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'signin_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SignInScreen();
  }
}

// // // Auth Credentials used woth firebase backend
