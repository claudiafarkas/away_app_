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

  @override
  void initState() {
    super.initState();
    // Initialize selection state for each location
    _selectedLocations = List<bool>.filled(
      widget.locations.length,
      false,
      growable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("🎈Import Success")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "💬 Parsed Caption:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.caption),
              SizedBox(height: 20),
              Text(
                "📍 Select Locations to Pin:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 300, // Set a fixed height for the ListView
                child: ListView.builder(
                  itemCount: widget.locations.length,
                  itemBuilder: (context, index) {
                    final loc = widget.locations[index];
                    // final lat = loc['latitude'], lng = loc['longitude'];
                    final lat = loc['latitude'] ?? loc['lat'];
                    final lng = loc['longitude'] ?? loc['lng'];
                    return Row(
                      children: [
                        // Checkbox on the left
                        Checkbox(
                          value: _selectedLocations[index],
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedLocations[index] = value ?? false;
                            });
                          },
                        ),
                        // Location details in the middle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(loc['address']),
                            ],
                          ),
                        ),
                        // Latitude and longitude on the right
                        Text(
                          "[$lat, $lng]",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      print(
                        "🧪 Button pressed. Current selected states: $_selectedLocations",
                      );
                      if (!_selectedLocations.contains(true)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please select at least one location.',
                            ),
                          ),
                        );
                        return;
                      }
                      // Filter selected locations into List<Map<String, dynamic>>
                      final selectedLocations =
                          widget.locations
                              .asMap()
                              .entries
                              .where((entry) => _selectedLocations[entry.key])
                              .map((entry) {
                                final loc = entry.value;
                                final lat = loc['latitude'] ?? loc['lat'];
                                final lng = loc['longitude'] ?? loc['lng'];

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
                              .whereType<
                                Map<String, dynamic>
                              >() // filters out nulls
                              .toList();
                      print(
                        "🗺 Navigating to map with locations: $selectedLocations",
                      );
                      // Add these locations to the singleton service
                      ImportService.instance.addLocations(selectedLocations);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapScreen(showDoneButton: true),
                        ),
                      );
                    },
                    child: Text("View Selected on Map"),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: Icon(Icons.edit_location_alt),
                    label: Text("Import Manually"),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/manual_import_screen',
                      );
                      if (result != null && mounted) {
                        setState(() {
                          widget.locations.add(result as Map<String, dynamic>);
                          _selectedLocations.add(false);
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
