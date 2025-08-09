import 'package:flutter/material.dart';
import '../views/home/home_screen.dart';
import '../views/import/link_import_screen.dart';
import '../views/map/map_screen.dart';
import '../views/deals/deals_screen.dart';
import '../views/profile/profile_screen.dart';

class BottomNavScaffold extends StatefulWidget {
  final int initialIndex;

  const BottomNavScaffold({super.key, this.initialIndex = 0});

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  late int _currentIndex;

  final List<Widget> _pages = [
    MyHomeScreen(),
    ImportLinkScreen(),
    MapScreen(),
    DealsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          _pages[_currentIndex],
          Positioned(
            left: 56,
            right: 56,
            bottom: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home),
                    iconSize: 25,
                    color: _currentIndex == 0 ? Color(0xFF062D40) : Colors.grey,
                    onPressed: () => setState(() => _currentIndex = 0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    iconSize: 25,
                    color: _currentIndex == 1 ? Color(0xFF062D40) : Colors.grey,
                    onPressed: () => setState(() => _currentIndex = 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.pin_drop_rounded),
                    iconSize: 25,
                    color: _currentIndex == 2 ? Color(0xFF062D40) : Colors.grey,
                    onPressed: () => setState(() => _currentIndex = 2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bubble_chart),
                    iconSize: 25,
                    color: _currentIndex == 3 ? Color(0xFF062D40) : Colors.grey,
                    onPressed: () => setState(() => _currentIndex = 3),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    iconSize: 25,
                    color: _currentIndex == 4 ? Color(0xFF062D40) : Colors.grey,
                    onPressed: () => setState(() => _currentIndex = 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
