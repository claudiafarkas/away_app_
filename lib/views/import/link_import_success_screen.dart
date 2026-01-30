// ABOUT: Page to confirm import, shows parsed info of video: caption and locatino
// link to imported saved page and link to map view
import 'package:flutter/material.dart';
import 'package:away/services/import_service.dart';
import 'package:away/views/map/map_screen.dart';
import 'package:away/views/import/manual_import_screen.dart';

class ImportSuccessScreen extends StatefulWidget {
  final String caption;
  final List<Map<String, dynamic>> locations;

  const ImportSuccessScreen({
    super.key,
    required this.caption,
    required this.locations,
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
    const sectionBg = Color(0xFFF4F6F9); // subtle light grey/blue
    final showToggle =
        _doesCaptionOverflow(context, widget.caption) || _isCaptionLong;
    // Tighter bottom padding when the caption is collapsed (to remove the visual gap).
    final double _captionBottomPadding =
        (_showFullCaption || !showToggle) ? 16.0 : 6.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header (no AppBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    splashRadius: 22,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Select Locations",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance the back button
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection area card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE6E8EC)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   "📍  Select Locations to Pin:",
                          //   style: theme.textTheme.titleMedium?.copyWith(
                          //     fontWeight: FontWeight.w700,
                          //   ),
                          // ),
                          const SizedBox(height: 12),

                          // Locations list (non-scrollable inside scroll view)
                          ListView.builder(
                            itemCount: widget.locations.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final loc = widget.locations[index];
                              final lat = loc['latitude'] ?? loc['lat'];
                              final lng = loc['longitude'] ?? loc['lng'];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _selectedLocations[index],
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _selectedLocations[index] =
                                              value ?? false;
                                        });
                                      },
                                      fillColor: WidgetStateProperty.resolveWith<
                                        Color
                                      >((Set<WidgetState> states) {
                                        if (states.contains(
                                          WidgetState.selected,
                                        )) {
                                          return const Color(
                                            0xFF062D40,
                                          ); // Dark blue when checked
                                        }
                                        return Colors
                                            .grey
                                            .shade300; // Light grey when unchecked
                                      }),
                                      checkColor:
                                          Colors.white, // White checkmark
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (loc['name'] ?? '').toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            (loc['address'] ?? '').toString(),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "[${lat ?? '-'}, ${lng ?? '-'}]",
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // View on Map button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
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
                                            'lat':
                                                lat is double
                                                    ? lat
                                                    : (lat as num).toDouble(),
                                            'lng':
                                                lng is double
                                                    ? lng
                                                    : (lng as num).toDouble(),
                                          };
                                        })
                                        .whereType<Map<String, dynamic>>()
                                        .toList();

                                print(
                                  "🗺 Navigating to map with locations: $selectedLocations",
                                );
                                ImportService.instance.addLocations(
                                  selectedLocations,
                                );
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
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE9F1F6),
                                foregroundColor: const Color(0xFF0B3954),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text("View Selected on Map"),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Parsed caption block
                    Container(
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        _captionBottomPadding,
                      ),
                      constraints: const BoxConstraints(minHeight: 220),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Parsed Caption:",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            widget.caption,
                            maxLines: _showFullCaption ? null : 6,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (showToggle)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed:
                                    () => setState(() {
                                      _showFullCaption = !_showFullCaption;
                                    }),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _showFullCaption ? 'Show less' : 'Show more',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0B3954),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32), // gap between sections
                    // Import Manually button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_location_alt),
                        label: const Text("Import Manually"),
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/manual_import_screen',
                          );
                          if (result != null && mounted) {
                            setState(() {
                              widget.locations.add(
                                result as Map<String, dynamic>,
                              );
                              _selectedLocations.add(false);
                            });
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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
