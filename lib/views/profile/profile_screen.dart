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
      {'title': 'Logout', 'icon': Icons.logout},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: accentColor,
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: accentColor),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              image: DecorationImage(
                                image:
                                    photoUrl != null
                                        ? NetworkImage(photoUrl!)
                                        : const AssetImage(
                                              'assets/avatar_placeholder.png',
                                            )
                                            as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name ?? 'Guest',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.star,
                                color: Colors.yellowAccent,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '120 Points',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // sliverList for settings items
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = settings[index];
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item['icon'] as IconData, color: accentColor),
                    title: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // TODO: Navigate to each setting’s detail page
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }, childCount: settings.length),
          ),
        ],
      ),
    );
  }
}
