// ABOUT: Page to confirm import, shows parsed info of video: caption and locatino
// link to imported saved page and link to map view
import 'package:flutter/material.dart';
import 'package:away/services/import_service.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/views/map/map_screen.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/soft_tile.dart';

class ImportSuccessScreen extends StatefulWidget {
  final String caption;
  final List<Map<String, dynamic>> locations;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? thumbnailStoragePath;
  final String? sourceUrl;

  const ImportSuccessScreen({
    super.key,
    required this.caption,
    required this.locations,
    this.videoUrl,
    this.thumbnailUrl,
    this.thumbnailStoragePath,
    this.sourceUrl,
  });

  @override
  State<ImportSuccessScreen> createState() => _ImportSuccessScreenState();
}

class _ImportSuccessScreenState extends State<ImportSuccessScreen> {
  // Track selected locations
  late List<bool> _selectedLocations;
  bool _showFullCaption = false;
  bool _isCaptionLong = false;

  // Returns true if the caption would exceed 6 lines with our text style
  bool _doesCaptionOverflow(BuildContext context, String text) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.4, color: Colors.black87);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 6,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    );
    // Page padding (16) + card padding (16) on both sides => 64 total
    final maxWidth = MediaQuery.of(context).size.width - 64;
    painter.layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  void initState() {
    super.initState();
    // Initialize selection state for each location
    _selectedLocations = List<bool>.filled(
      widget.locations.length,
      false,
      growable: true,
    );
    // Determine if caption is long enough to collapse
    // More lenient thresholds so the toggle is shown more reliably.
    final cleaned = widget.caption.trim();
    final lines = '\n'.allMatches(cleaned).length + 1;
    _isCaptionLong = cleaned.length > 160 || lines >= 4;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showToggle =
        _doesCaptionOverflow(context, widget.caption) || _isCaptionLong;
    // Tighter bottom padding when the caption is collapsed (to remove the visual gap).
    final double _captionBottomPadding =
        (_showFullCaption || !showToggle) ? 16.0 : 6.0;

    return CloudScaffold(
      fadeBottom: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Select locations',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SoftTile(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListView.builder(
                            itemCount: widget.locations.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final loc = widget.locations[index];
                              final lat = loc['latitude'] ?? loc['lat'];
                              final lng = loc['longitude'] ?? loc['lng'];
                              final selected = _selectedLocations[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      _selectedLocations[index] = !selected;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          selected
                                              ? AppColors.sky.withValues(
                                                alpha: 0.55,
                                              )
                                              : AppColors.mist.withValues(
                                                alpha: 0.7,
                                              ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: AppColors.inkDeep,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (loc['name'] ?? '').toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                (loc['address'] ?? '')
                                                    .toString(),
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '[${lat ?? '-'}, ${lng ?? '-'}]',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.muted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () async {
                                print(
                                  "🧪 Button pressed. Current selected states: $_selectedLocations",
                                );
                                if (!_selectedLocations.contains(true)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select at least one location.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final selectedLocations =
                                    widget.locations
                                        .asMap()
                                        .entries
                                        .where(
                                          (entry) =>
                                              _selectedLocations[entry.key],
                                        )
                                        .map((entry) {
                                          final loc = entry.value;
                                          final lat =
                                              loc['latitude'] ?? loc['lat'];
                                          final lng =
                                              loc['longitude'] ?? loc['lng'];
                                          if (lat == null || lng == null) {
                                            print(
                                              "⚠️ Skipping location with null coordinates: ${loc['name']}",
                                            );
                                            return null;
                                          }
                                          return {
                                            'name': loc['name'] ?? 'Unknown',
                                            'address': loc['address'] ?? '',
                                            'city': loc['city'] ?? '',
                                            'country': loc['country'] ?? '',
                                            'lat':
                                                lat is double
                                                    ? lat
                                                    : (lat as num).toDouble(),
                                            'lng':
                                                lng is double
                                                    ? lng
                                                    : (lng as num).toDouble(),
                                            'videoUrl': widget.videoUrl,
                                            'thumbnailUrl': widget.thumbnailUrl,
                                            'thumbnailStoragePath':
                                                widget.thumbnailStoragePath,
                                            'sourceUrl': widget.sourceUrl,
                                            'caption': widget.caption,
                                          };
                                        })
                                        .whereType<Map<String, dynamic>>()
                                        .toList();

                                print(
                                  "🗺 Navigating to map with locations: $selectedLocations",
                                );
                                await ImportService.instance
                                    .addAndPersistLocations(selectedLocations);
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const MapScreen(
                                          showDoneButton: true,
                                        ),
                                  ),
                                );
                              },
                              child: const Text('View selected on map'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SoftTile(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        _captionBottomPadding,
                      ),
                      color: AppColors.mist.withValues(alpha: 0.85),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parsed caption',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            widget.caption,
                            maxLines: _showFullCaption ? null : 6,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: AppColors.ink,
                            ),
                          ),
                          if (showToggle)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed:
                                    () => setState(() {
                                      _showFullCaption = !_showFullCaption;
                                    }),
                                child: Text(
                                  _showFullCaption ? 'Show less' : 'Show more',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_location_alt_rounded),
                        label: const Text('Import manually'),
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/manual_import_screen',
                          );
                          if (result != null && mounted) {
                            final pin = Map<String, dynamic>.from(
                              result as Map,
                            );
                            setState(() {
                              widget.locations.add(pin);
                              _selectedLocations.add(true);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
