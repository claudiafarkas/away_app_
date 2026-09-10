import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:away/data/preview_content.dart';
import 'package:away/services/import_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pin_card.dart';
import '../../widgets/soft_tile.dart';
import '../imported/imported_screen.dart';

class _FeedItem {
  const _FeedItem({
    required this.name,
    required this.address,
    this.thumbUrl = '',
    this.lat,
    this.lng,
    this.promoted,
  });

  final String name;
  final String address;
  final String thumbUrl;
  final double? lat;
  final double? lng;
  final PreviewAd? promoted;

  bool get isPromoted => promoted != null;
}

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  static const _suggestions = [
    (Icons.restaurant_rounded, 'Eat'),
    (Icons.hotel_rounded, 'Stay'),
    (Icons.park_rounded, 'Walk'),
    (Icons.water_rounded, 'Coast'),
    (Icons.auto_awesome_rounded, 'Hidden'),
  ];

  static const _placeholderPins = [
    ('Hidden courtyard café', 'Chiado, Lisbon'),
    ('Night market stall', 'Shibuya, Tokyo'),
    ('Cliff lookout', 'Big Sur, California'),
    ('Rooftop tiles', 'Trastevere, Rome'),
    ('Harbor bakery', 'Copenhagen, Denmark'),
    ('Garden bookshop', 'Notting Hill, London'),
  ];

  String? _selectedExplore;

  List<_FeedItem> _buildFeed() {
    final imported = ImportService.instance.importedLocations;
    final organic = <_FeedItem>[];
    if (imported.isNotEmpty) {
      for (final pin in imported) {
        organic.add(
          _FeedItem(
            name: pin['name'] as String? ?? 'Unknown',
            address: pin['address'] as String? ?? '',
            thumbUrl: (pin['thumbnailUrl'] as String? ?? '').trim(),
            lat: pin['lat'] is num ? (pin['lat'] as num).toDouble() : null,
            lng: pin['lng'] is num ? (pin['lng'] as num).toDouble() : null,
          ),
        );
      }
    } else {
      for (final sample in _placeholderPins) {
        organic.add(_FeedItem(name: sample.$1, address: sample.$2));
      }
    }

    final feed = <_FeedItem>[];
    for (var i = 0; i < organic.length; i++) {
      feed.add(organic[i]);
      if (i == 1 && PreviewContent.ads.isNotEmpty) {
        final ad = PreviewContent.ads[0];
        feed.add(_FeedItem(name: ad.name, address: ad.address, promoted: ad));
      }
      if (i == 4 && PreviewContent.ads.length > 1) {
        final ad = PreviewContent.ads[1];
        feed.add(_FeedItem(name: ad.name, address: ad.address, promoted: ad));
      }
    }
    if (!feed.any((item) => item.isPromoted)) {
      for (final ad in PreviewContent.ads) {
        feed.add(_FeedItem(name: ad.name, address: ad.address, promoted: ad));
      }
    }
    return feed;
  }

  Future<void> _openPromoted(PreviewAd ad) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.north_east_rounded,
                    size: 18,
                    color: AppColors.inkDeep,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ad · ${ad.advertiser}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ad.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ad.address,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(ad.clickUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: const Text('Open site'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Not now'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final imported = ImportService.instance.importedLocations;
    final hasImported = imported.isNotEmpty;
    final feed = _buildFeed();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topInset + 72)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 168,
                child: PageView.builder(
                  padEnds: false,
                  controller: PageController(viewportFraction: 0.86),
                  itemCount: PreviewContent.inspired.length,
                  itemBuilder: (context, index) {
                    final item = PreviewContent.inspired[index];
                    return SoftTile(
                      margin: EdgeInsets.only(
                        left: index == 0 ? 20 : 8,
                        right:
                            index == PreviewContent.inspired.length - 1
                                ? 20
                                : 8,
                      ),
                      padding: const EdgeInsets.all(20),
                      gradient:
                          AppColors.featuredGradients[index %
                              AppColors.featuredGradients.length],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Inspired for you',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.$1,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Explore',
                subtitle: 'Soft collections to wander through',
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 92,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    final selected = _selectedExplore == item.$2;
                    return SoftTile(
                      width: 86,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      radius: 20,
                      color:
                          selected
                              ? AppColors.sky.withValues(alpha: 0.85)
                              : null,
                      onTap: () {
                        setState(() {
                          _selectedExplore = selected ? null : item.$2;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.$1, color: AppColors.inkDeep, size: 22),
                          const SizedBox(height: 8),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: hasImported ? 'Your places' : 'Saved-looking tiles',
                subtitle:
                    hasImported
                        ? 'Your pins, with a few native recs mixed in'
                        : 'Placeholder masonry while your feed is empty',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 128),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childCount: feed.length,
                itemBuilder: (context, index) {
                  final item = feed[index];
                  return PinCard(
                    name: item.name,
                    address: item.address,
                    thumbUrl: item.thumbUrl,
                    lat: item.lat,
                    lng: item.lng,
                    imageHeight: [168.0, 210.0, 186.0, 228.0][index % 4],
                    gradientIndex: item.promoted?.gradientIndex ?? index,
                    isPromoted: item.isPromoted,
                    onTap:
                        item.promoted == null
                            ? null
                            : () => _openPromoted(item.promoted!),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: topInset + 8,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: GlassPill(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.muted),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search places',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GlassPill(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyImportsScreen()),
                  );
                },
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.layers_rounded,
                  color: AppColors.inkDeep,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
