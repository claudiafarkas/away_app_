import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CloudBackdrop extends StatelessWidget {
  final Widget child;
  final bool fadeBottom;

  const CloudBackdrop({
    super.key,
    required this.child,
    this.fadeBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.skyGradient),
          ),
        ),
        Positioned(
          top: -90,
          right: -50,
          child: _blob(200, AppColors.sky.withValues(alpha: 0.18)),
        ),
        Positioned(
          top: 220,
          left: -110,
          child: _blob(230, AppColors.peach.withValues(alpha: 0.12)),
        ),
        Positioned(
          bottom: 90,
          right: -90,
          child: _blob(210, AppColors.lavender.withValues(alpha: 0.12)),
        ),
        Positioned(
          bottom: -50,
          left: 30,
          child: _blob(160, AppColors.sage.withValues(alpha: 0.14)),
        ),
        if (fadeBottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      const Color(0xE6F4F7FA),
                    ],
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 64,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

class CloudScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool fadeBottom;

  const CloudScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.fadeBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return CloudBackdrop(
      fadeBottom: fadeBottom,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
