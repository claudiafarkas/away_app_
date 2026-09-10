import 'package:flutter/material.dart';

/// Soft, cloudy palette: Pinterest air + Wealthsimple calm + Apple Maps chrome.
class AppColors {
  static const ink = Color(0xFF1B3A48);
  static const inkDeep = Color(0xFF062D40);
  static const muted = Color(0xFF6B7C86);
  static const mist = Color(0xFFF4F7FA);
  static const cream = Color(0xFFF8F4EE);
  static const cloud = Color(0xFFFFFFFF);
  static const sky = Color(0xFFD5E7F2);
  static const peach = Color(0xFFF6E4D8);
  static const sage = Color(0xFFDCE8E1);
  static const lavender = Color(0xFFE6E1F2);
  static const sand = Color(0xFFF1E8DA);
  static const hairline = Color(0x1A1B3A48);
  static const shadow = Color(0x14062D40);

  static const skyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FBFD), Color(0xFFEEF4F8), Color(0xFFF7F1E9)],
  );

  static const featuredGradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8F2F7), Color(0xFFF6E8DC)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE7E4F4), Color(0xFFD7E8F0)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFDCE9E3), Color(0xFFF0E7D8)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF3E6DC), Color(0xFFDDE8F2)],
    ),
  ];

  static const pinFallbackGradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFDDEAF1), Color(0xFFBFD4E2)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8DDD4), Color(0xFFD4C4B6)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD7E4DC), Color(0xFFB7C9BF)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE4DDEE), Color(0xFFC9BCDD)],
    ),
  ];
}
