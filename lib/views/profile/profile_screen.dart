import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../auth/signin_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
        backgroundColor: const Color(0xFF062D40),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Privacy Policy\n\n'
            'Away values your privacy. This Privacy Policy explains how we collect, use, and protect your information when you use the Away app.\n\n'
            'Information We Collect\n'
            '• Account Information: When you sign in, we collect your name and email address to authenticate your account.\n'
            '• User Content: Video links, saved locations, map pins, and related metadata you choose to provide.\n'
            '• Location Information: Location data associated with places you save or view. Away does not track real-time background location.\n'
            '• Usage & Diagnostics: Basic usage, crash, and performance data to improve stability.\n\n'
            'How We Use Your Information\n'
            '• Authenticate users\n'
            '• Enable app features\n'
            '• Save and display user content\n'
            '• Maintain performance and security\n\n'
            'Data Sharing\n'
            'Away does not sell or share personal data with advertisers. Trusted third-party services (Firebase, Google Maps) are used only for core functionality.\n\n'
            'Tracking\n'
            'Away does not track users across apps or websites and does not use data for targeted advertising.\n\n'
            'Data Security\n'
            'We use industry-standard security practices to protect your information.\n\n'
            'Your Choices\n'
            'You may manage or delete your data by signing out or discontinuing use of the app.\n\n'
            'Contact\n'
            'discoveraway.app@gmail.com',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
        backgroundColor: const Color(0xFF062D40),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${user?.displayName ?? 'Not set'}'),
              const SizedBox(height: 12),
              Text('Email: ${user?.email ?? 'Not set'}'),
              const SizedBox(height: 24),
              const Text(
                'Profile updates will be added in a future version.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginSecurityScreen extends StatelessWidget {
  const LoginSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login & Security'),
        backgroundColor: const Color(0xFF062D40),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Password updates and advanced security controls will be available in a future update.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    final email = user?.email;
    final photoUrl = user?.photoURL;

    const accentColor = Color(0xFF062D40);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 62),
                if (user != null) ...[
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child:
                          photoUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Hey ${name ?? 'there'}!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (email != null)
                    Center(
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ] else ...[
                  const Center(
                    child: Text(
                      'Hey there!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                _buildListTileWithSubtitle(
                  'Personal Info',
                  'Update your name, email, or profile photo',
                  Icons.person,
                  accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalInfoScreen(),
                      ),
                    );
                  },
                ),

                // Removed 'Account Management' tile
                _buildListTileWithSubtitle(
                  'Notifications',
                  'Control your notification settings',
                  Icons.notifications,
                  accentColor,
                  onTap: () async {
                    final uri = Uri.parse('app-settings:');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                _buildListTileWithSubtitle(
                  'Privacy & Data',
                  'Manage what you share with the app',
                  Icons.lock_outline,
                  accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyScreen(),
                      ),
                    );
                  },
                ),
                _buildListTileWithSubtitle(
                  'Login & Security',
                  'Update password or secure your account',
                  Icons.security,
                  accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginSecurityScreen(),
                      ),
                    );
                  },
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
                // Removed 'Help/Legal' tile
                // Removed 'Accessibility' tile
                // Removed 'Ad Preferences' tile
                _buildListTile(
                  'Give Us Your Feedback',
                  Icons.feedback_outlined,
                  accentColor,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            contentPadding: const EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text(
                              'Send Feedback',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'We’d love to hear from you!',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please send your feedback to:',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'discoveraway.app@gmail.com',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            actionsPadding: const EdgeInsets.only(
                              right: 8,
                              bottom: 8,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: TextButton(
                      onPressed: () async {
                        await AuthService.instance.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: accentColor,
                        side: const BorderSide(color: accentColor),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTileWithSubtitle(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor, {
    void Function()? onTap,
  }) {
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
          onTap:
              onTap ??
              () {
                // TODO: Implement navigation logic
              },
        ),
      ],
    );
  }

  Widget _buildListTile(
    String title,
    IconData icon,
    Color iconColor, {
    void Function()? onTap,
  }) {
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
      onTap:
          onTap ??
          () {
            // TODO: Implement navigation logic
          },
    );
  }
}
