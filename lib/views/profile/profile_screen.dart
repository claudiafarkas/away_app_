import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _email;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final fullName = user.displayName ?? '';
      final nameParts = fullName.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _email = user.email;
      _photoUrl = user.photoURL;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) {
      print('⚠️ Image picking cancelled');
      return;
    }

    print('🖼 Picked image path: ${picked.path}');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No authenticated user — cannot upload profile image');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to update your photo'),
        ),
      );
      return;
    }

    print('👤 Uploading profile photo for UID: ${user.uid}');

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('user_profiles')
        .child('${user.uid}.jpg');

    print('☁️ Firebase Storage path: ${storageRef.fullPath}');

    try {
      // Read file as bytes
      final file = File(picked.path);
      print('📂 Exists: ${await file.exists()}');
      final fileSize = await file.length();
      print('📏 File size: $fileSize');

      // Upload using bytes instead of File
      try {
        final fileBytes = await file.readAsBytes();
        print('📖 File read as bytes: ${fileBytes.length} bytes');

        await storageRef.putData(
          fileBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        print('✅ Image uploaded to Firebase Storage');
      } catch (uploadError) {
        print('❌ Upload failed: $uploadError');
        rethrow;
      }

      // Get download URL
      try {
        final downloadUrl = await storageRef.getDownloadURL();
        print('🔗 Download URL received: $downloadUrl');

        // Update Firebase Auth profile
        await user.updatePhotoURL(downloadUrl);
        print('✅ Photo URL updated in Auth');

        await user.reload();
        print('✅ User reloaded');

        final refreshedUser = FirebaseAuth.instance.currentUser;
        print('🔄 Reloaded user photoURL: ${refreshedUser?.photoURL}');

        setState(() {
          _photoUrl = refreshedUser?.photoURL;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } catch (urlError) {
        print('❌ Download URL retrieval failed: $urlError');
        rethrow;
      }
    } catch (e, stack) {
      print('❌ Error updating profile picture: $e');
      print('Stack trace: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile picture')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      final newName =
          '${_firstNameController.text} ${_lastNameController.text}';
      print('Updating display name to: $newName');

      await user?.updateDisplayName(newName);

      if (_photoUrl != null && !_photoUrl!.startsWith('http')) {
        // If it's a local path, you'd typically upload to storage and get a URL
        // For now, we just skip updating photoURL
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
        backgroundColor: const Color(0xFF062D40),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          _photoUrl != null
                              ? (_photoUrl!.startsWith('http')
                                  ? NetworkImage(_photoUrl!)
                                  : FileImage(File(_photoUrl!))
                                      as ImageProvider)
                              : null,
                      child:
                          _photoUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                    ),
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter your first name'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter your last name'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF062D40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Save Changes'),
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

  Future<void> _deleteAccount(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to permanently delete your account?\n\n'
            'This action cannot be undone. All your data, including:\n'
            '• Profile information\n'
            '• Saved videos and locations\n'
            '• Map pins and collections\n\n'
            'will be permanently deleted.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting your account...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      final uid = user.uid;

      // Delete Firestore user data
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // Delete any related collections (videos, locations, etc.)
      // Add more collections as needed
      final videosSnapshot =
          await FirebaseFirestore.instance
              .collection('videos')
              .where('userId', isEqualTo: uid)
              .get();
      for (var doc in videosSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth user
      await user.delete();

      // Close loading dialog
      if (!context.mounted) return;
      Navigator.of(context).pop();

      // Navigate to sign in screen
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been successfully deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (!context.mounted) return;
      Navigator.of(context).pop();

      // Show error dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Failed to delete account. Please try again or contact support.\n\nError: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Password updates and advanced security controls will be available in a future update.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _deleteAccount(context),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Permanently delete your account and all associated data. This action cannot be undone.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
                  onTap: () async {
                    // Await navigation and refresh on return
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalInfoScreen(),
                      ),
                    );
                    setState(() {});
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
