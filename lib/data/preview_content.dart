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

class TripDay {
  const TripDay({
    required this.date,
    this.who = '',
    this.what = '',
    this.where = '',
    this.when = '',
    this.why = '',
  });

  final DateTime date;
  final String who;
  final String what;
  final String where;
  final String when;
  final String why;

  String get weekdayLabel {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[date.weekday - 1]} ${date.day}';
  }

  String get cardTitle {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '$weekdayLabel · ${months[date.month - 1]}';
  }

  String get summary {
    final parts = [what, where].map((s) => s.trim()).where((s) => s.isNotEmpty);
    return parts.join(' · ');
  }

  TripDay copyWith({
    DateTime? date,
    String? who,
    String? what,
    String? where,
    String? when,
    String? why,
  }) {
    return TripDay(
      date: date ?? this.date,
      who: who ?? this.who,
      what: what ?? this.what,
      where: where ?? this.where,
      when: when ?? this.when,
      why: why ?? this.why,
    );
  }
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
  final List<TripDay> days;

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    return !d.isBefore(a) && !d.isAfter(b);
  }

  PreviewTrip copyWith({
    String? title,
    String? place,
    DateTime? start,
    DateTime? end,
    Color? color,
    List<TripDay>? days,
  }) {
    return PreviewTrip(
      id: id,
      title: title ?? this.title,
      place: place ?? this.place,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
      days: days ?? this.days,
    );
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
        TripDay(
          date: DateTime(2026, 6, 12),
          who: 'Just us',
          what: 'Chiado café + tram 28',
          where: 'Chiado',
          when: 'Morning into afternoon',
          why: 'Ease in and get the lay of the streets',
        ),
        TripDay(
          date: DateTime(2026, 6, 13),
          who: 'Just us',
          what: 'Market morning, then wander Alfama',
          where: 'Alfama',
          when: 'Morning',
          why: 'Food first, then the old neighborhood',
        ),
        TripDay(
          date: DateTime(2026, 6, 14),
          who: 'Just us',
          what: 'Coast day',
          where: 'Cascais',
          when: 'All day',
          why: 'Leave the city without losing the trip',
        ),
        TripDay(
          date: DateTime(2026, 6, 15),
          what: 'Open afternoon',
          where: 'Lisbon',
          when: 'Afternoon',
          why: 'Buffer day — fill from saved pins if we want',
        ),
        TripDay(
          date: DateTime(2026, 6, 16),
          who: 'Dinner with friends',
          what: 'Dinner notes',
          where: 'Bairro Alto',
          when: 'Evening',
          why: 'The night we actually dressed up for',
        ),
        TripDay(
          date: DateTime(2026, 6, 17),
          what: 'Hidden courtyards',
          where: 'Lisbon',
          when: 'Late morning',
          why: 'Slow streets, no agenda',
        ),
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
        TripDay(
          date: DateTime(2026, 10, 3),
          who: 'Just us',
          what: 'Arrive, lantern walk',
          where: 'Yanaka / old streets',
          when: 'Evening',
          why: 'Land softly, no big plans',
        ),
        TripDay(
          date: DateTime(2026, 10, 4),
          what: 'Shibuya + side streets',
          where: 'Shibuya',
          when: 'Afternoon into night',
          why: 'See the crush, then get off it',
        ),
        TripDay(
          date: DateTime(2026, 10, 5),
          who: 'Just us',
          what: 'Day trip',
          where: 'Kamakura',
          when: 'All day',
          why: 'Sea air after the city',
        ),
        TripDay(
          date: DateTime(2026, 10, 6),
          what: 'Open',
          where: 'Tokyo',
          why: 'Leave room for a pin we already saved',
        ),
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
        TripDay(
          date: DateTime(2026, 12, 18),
          who: 'Just us',
          what: 'Drive the coast',
          where: 'Highway 1',
          when: 'Daylight',
          why: 'The whole point is the road',
        ),
        TripDay(
          date: DateTime(2026, 12, 19),
          what: 'Cliff lookout',
          where: 'Big Sur',
          when: 'Morning',
          why: 'Fog, then coffee',
        ),
        TripDay(
          date: DateTime(2026, 12, 20),
          what: 'Quiet coves',
          where: 'Big Sur',
          when: 'Unscheduled',
          why: 'Do less than we think we should',
        ),
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
