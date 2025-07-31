import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final user = FirebaseAuth.instance.currentUser;

String? name = user?.displayName;
String? email = user?.email;
String? photoUrl = user?.photoURL;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF062D40);
    final settings = [
      {'title': 'Personal Info', 'icon': Icons.person},
      {'title': 'Account Management', 'icon': Icons.manage_accounts},
      {'title': 'Notifications', 'icon': Icons.notifications},
      {'title': 'Privacy & Data', 'icon': Icons.lock_outline},
      {'title': 'Login & Security', 'icon': Icons.security},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const SizedBox(height: 62),
          const Text(
            'Hey Test!', // ToDO - Replace with dynamic user name
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          _buildListTileWithSubtitle(
            'Personal Info',
            'Update your name, email, or profile photo',
            Icons.person,
            accentColor,
          ),
          _buildListTileWithSubtitle(
            'Account Management',
            'Manage your preferences and account details',
            Icons.manage_accounts,
            accentColor,
          ),
          _buildListTileWithSubtitle(
            'Notifications',
            'Control your notification settings',
            Icons.notifications,
            accentColor,
          ),
          _buildListTileWithSubtitle(
            'Privacy & Data',
            'Manage what you share with the app',
            Icons.lock_outline,
            accentColor,
          ),
          _buildListTileWithSubtitle(
            'Login & Security',
            'Update password or secure your account',
            Icons.security,
            accentColor,
          ),

          const SizedBox(height: 32),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'HELP & MORE',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildListTile('Help/Legal', Icons.help_outline, accentColor),
          _buildListTile('Accessibility', Icons.accessibility, accentColor),
          _buildListTile('Ad Preferences', Icons.tune, accentColor),
          _buildListTile(
            'Give Us Your Feedback',
            Icons.feedback_outlined,
            accentColor,
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () {
              // TODO: Add sign-out functionality here
            },
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              side: const BorderSide(color: accentColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildListTileWithSubtitle(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 8,
          ),
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            // TODO: Implement navigation logic
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildListTile(String title, IconData icon, Color iconColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // TODO: Implement navigation logic
      },
    );
  }
}
