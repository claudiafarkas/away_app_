import 'package:flutter/material.dart';
import 'package:away/data/preview_content.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/widgets/soft_tile.dart';
import 'plan_chat_screen.dart';
import 'trip_detail_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 128),
        children: [
          SectionHeader(
            title: 'Plans',
            subtitle: 'See the year, then fill a trip',
            trailing: GlassPill(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlanChatScreen()),
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppColors.inkDeep,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Plan with AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _YearChip(label: '2026', selected: true),
                const SizedBox(width: 8),
                const _YearChip(label: '2027', selected: false),
                const Spacer(),
                Text(
                  '${PreviewContent.trips.length} trips',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: PreviewContent.trips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final trip = PreviewContent.trips[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailScreen(trip: trip),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: trip.color.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Text(
                      '${trip.place}  ${_shortRange(trip)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                return _MiniMonthCard(
                  year: 2026,
                  month: month,
                  trips: PreviewContent.trips,
                  onTripTap: (trip) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailScreen(trip: trip),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _shortRange(PreviewTrip trip) {
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
    return '${months[trip.start.month - 1]} ${trip.start.day}–${trip.end.day}';
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            selected
                ? AppColors.inkDeep
                : AppColors.cloud.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.ink,
        ),
      ),
    );
  }
}

class _MiniMonthCard extends StatelessWidget {
  const _MiniMonthCard({
    required this.year,
    required this.month,
    required this.trips,
    required this.onTripTap,
  });

  final int year;
  final int month;
  final List<PreviewTrip> trips;
  final ValueChanged<PreviewTrip> onTripTap;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = (first.weekday + 6) % 7; // Monday-first
    final monthTrips =
        trips
            .where(
              (t) =>
                  t.start.month == month ||
                  t.end.month == month ||
                  (t.start.isBefore(DateTime(year, month + 1, 1)) &&
                      t.end.isAfter(DateTime(year, month, 0))),
            )
            .toList();

    return SoftTile(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      onTap: monthTrips.isEmpty ? null : () => onTripTap(monthTrips.first),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthNames[month - 1],
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _Dow('M'),
              _Dow('T'),
              _Dow('W'),
              _Dow('T'),
              _Dow('F'),
              _Dow('S'),
              _Dow('S'),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: leading + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final day = index - leading + 1;
              final date = DateTime(year, month, day);
              PreviewTrip? hit;
              for (final trip in trips) {
                if (trip.covers(date)) {
                  hit = trip;
                  break;
                }
              }
              return Center(
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hit?.color.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight:
                          hit != null ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.ink.withValues(
                        alpha: hit != null ? 0.95 : 0.55,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Dow extends StatelessWidget {
  const _Dow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
