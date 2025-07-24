// lib/widgets/social_signin_button.dart
import 'package:flutter/material.dart';

/// A reusable button for social sign-in (e.g., Google, Apple).
class SocialSignInButton extends StatelessWidget {
  final String assetName; // Path to the social logo asset
  final String text;
  final VoidCallback onPressed;

  const SocialSignInButton({
    Key? key,
    required this.assetName,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFCCCCCC)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(assetName, height: 24, width: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
