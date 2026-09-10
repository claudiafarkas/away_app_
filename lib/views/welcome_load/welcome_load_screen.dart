import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cloud_backdrop.dart';
import '../auth/auth_flow.dart';
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
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    if (FirebaseAuth.instance.currentUser != null) {
      await enterSignedInApp(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CloudBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Away.', style: AppTheme.wordmark),
              const SizedBox(height: 12),
              Text(
                'places, softly collected',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(letterSpacing: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
