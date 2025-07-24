import 'package:flutter/material.dart';
import '../auth/auth_screen.dart';

class WelcomeLoad extends StatefulWidget {
  const WelcomeLoad({super.key});

  @override
  State<WelcomeLoad> createState() => _WelcomeLoadState();
}

class _WelcomeLoadState extends State<WelcomeLoad> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF062D40),
      body: Center(
        child: Text(
          'Away.',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 244, 241, 219),
            fontFamily: 'Times New Roman',
          ),
        ),
      ),
    );
  }
}
