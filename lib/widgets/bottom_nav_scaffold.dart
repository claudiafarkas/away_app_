import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../views/home/home_screen.dart';
import '../views/import/link_import_screen.dart';
import '../views/map/map_screen.dart';
import '../views/calendar/calendar_screen.dart';
import '../views/profile/profile_screen.dart';
import '../services/share_intent_service.dart';
import 'cloud_backdrop.dart';

class BottomNavScaffold extends StatefulWidget {
  final int initialIndex;
  final String? initialImportUrl;

  const BottomNavScaffold({
    super.key,
    this.initialIndex = 0,
    this.initialImportUrl,
  });

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold>
    with WidgetsBindingObserver {
  late int _currentIndex;
  String? _pendingImportUrl;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.add_rounded, 'Add'),
    (Icons.near_me_rounded, 'Map'),
    (Icons.auto_awesome_rounded, 'Plans'),
    (Icons.person_rounded, 'You'),
  ];

  List<Widget> _buildPages() {
    return [
      const MyHomeScreen(),
      ImportLinkScreen(initialUrl: _pendingImportUrl),
      const MapScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _pendingImportUrl = widget.initialImportUrl;
    if ((_pendingImportUrl ?? '').isNotEmpty) {
      _currentIndex = 1;
    }
    _consumePendingSharedUrl();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _consumePendingSharedUrl();
    }
  }

  Future<void> _consumePendingSharedUrl() async {
    await ShareIntentService.instance.refreshFromNative();
    final sharedUrl = ShareIntentService.instance.consumeSharedUrl();
    if (!mounted) return;
    if (sharedUrl != null && sharedUrl.trim().isNotEmpty) {
      setState(() {
        _pendingImportUrl = sharedUrl.trim();
        _currentIndex = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CloudBackdrop(
      fadeBottom: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            _buildPages()[_currentIndex],
            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.hairline),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(_items.length, (index) {
                      final selected = _currentIndex == index;
                      final item = _items[index];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _currentIndex = index),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? AppColors.sky.withValues(alpha: 0.7)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.$1,
                                  size: 20,
                                  color:
                                      selected
                                          ? AppColors.inkDeep
                                          : AppColors.muted,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.$2,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight:
                                        selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                    color:
                                        selected
                                            ? AppColors.inkDeep
                                            : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
