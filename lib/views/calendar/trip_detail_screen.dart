import 'package:flutter/material.dart';
import 'package:away/data/preview_content.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/soft_tile.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.trip});

  final PreviewTrip trip;

  @override
  Widget build(BuildContext context) {
    return CloudBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(trip.title)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            SoftTile(
              gradient: AppColors.featuredGradients[0],
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.place,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_fmt(trip.start)} – ${_fmt(trip.end)}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SectionHeader(
              title: 'Day plan',
              subtitle: 'A preview itinerary — not saved yet',
            ),
            for (final day in trip.days)
              SoftTile(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: trip.color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.$1,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            day.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Would export these days to your phone calendar.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Export to calendar'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}';
  }
}
