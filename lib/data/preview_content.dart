import 'package:flutter/material.dart';
import 'package:away/theme/app_colors.dart';

/// Static preview data for UI scaffolds. Not persisted.
class PreviewAd {
  const PreviewAd({
    required this.name,
    required this.address,
    required this.advertiser,
    required this.clickUrl,
    required this.gradientIndex,
  });

  final String name;
  final String address;
  final String advertiser;
  final String clickUrl;
  final int gradientIndex;
}

class PreviewTrip {
  const PreviewTrip({
    required this.id,
    required this.title,
    required this.place,
    required this.start,
    required this.end,
    required this.color,
    required this.days,
  });

  final String id;
  final String title;
  final String place;
  final DateTime start;
  final DateTime end;
  final Color color;
  final List<(String, String)> days;

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    return !d.isBefore(a) && !d.isAfter(b);
  }
}

class PreviewContent {
  static const ads = [
    PreviewAd(
      name: 'Portugal: Atlantic small group',
      address: 'G Adventures · 8 days from Lisbon',
      advertiser: 'G Adventures',
      clickUrl: 'https://www.gadventures.com/',
      gradientIndex: 2,
    ),
    PreviewAd(
      name: 'Points on every stay',
      address: 'Away Travel Card · no foreign fees',
      advertiser: 'Away Travel Card',
      clickUrl: 'https://www.google.com/search?q=travel+credit+card',
      gradientIndex: 1,
    ),
  ];

  static final trips = [
    PreviewTrip(
      id: 'lisbon-2026',
      title: 'Lisbon walk',
      place: 'Lisbon',
      start: DateTime(2026, 6, 12),
      end: DateTime(2026, 6, 20),
      color: const Color(0xFF8FA9B8),
      days: [
        ('Fri 12', 'Chiado café + tram 28'),
        ('Sat 13', 'Market morning, Alfama'),
        ('Sun 14', 'Coast day, Cascais'),
        ('Mon 15', 'Open afternoon'),
        ('Tue 16', 'Dinner notes, Bairro Alto'),
        ('Wed 17', 'Hidden courtyards'),
      ],
    ),
    PreviewTrip(
      id: 'tokyo-2026',
      title: 'Tokyo evenings',
      place: 'Tokyo',
      start: DateTime(2026, 10, 3),
      end: DateTime(2026, 10, 14),
      color: const Color(0xFFB8A9C9),
      days: [
        ('Sat 3', 'Arrive, lantern walk'),
        ('Sun 4', 'Shibuya + side streets'),
        ('Mon 5', 'Day trip, Kamakura'),
        ('Tue 6', 'Open'),
      ],
    ),
    PreviewTrip(
      id: 'bigsur-2026',
      title: 'Pacific fog',
      place: 'Big Sur',
      start: DateTime(2026, 12, 18),
      end: DateTime(2026, 12, 23),
      color: const Color(0xFF9BB5A8),
      days: [
        ('Fri 18', 'Drive the coast'),
        ('Sat 19', 'Cliff lookout'),
        ('Sun 20', 'Quiet coves'),
      ],
    ),
  ];

  static const inspired = [
    ('Lisbon light', 'Sun-washed streets and pastel tiles'),
    ('Tokyo evenings', 'Lanterns, side streets, late bowls'),
    ('Pacific fog', 'Cliffs, long drives, quiet coves'),
    ('Rome courtyards', 'Hidden tables and warm stone'),
  ];

  static Color tripColor(PreviewTrip trip) => trip.color;

  static List<Color> get monthAccents => [
    AppColors.sky,
    AppColors.lavender,
    AppColors.sage,
    AppColors.peach,
  ];
}
