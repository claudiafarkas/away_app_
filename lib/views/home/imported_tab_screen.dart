import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:away/services/import_service.dart';

class MyImportsTabScreen extends StatefulWidget {
  const MyImportsTabScreen({super.key});

  @override
  State<MyImportsTabScreen> createState() => _MyImportsTabScreenState();
}

class _MyImportsTabScreenState extends State<MyImportsTabScreen> {
  /// Track custom “boards” (folders) beyond “All Locations”
  final List<String> _boardNames = ["All Locations"];
  final Map<String, List<Map<String, dynamic>>> _customBoards = {};

  /// When in “Select” mode, keep track of which indices are checked
  final Set<int> _selectedIndices = {};

  /// Whether we’re currently in “Select” mode
  bool _isSelectionMode = false;

  /// Which text‐based “tags” (city/country/name/address‐fragments) are currently applied
  final Set<String> _appliedFilters = {};

  // Open a dialog to create a brand‐new folder (board)
  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("New Folder"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Folder name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty && !_boardNames.contains(name)) {
                    setState(() {
                      _boardNames.add(name);
                      _customBoards[name] = [];
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text("Create"),
              ),
            ],
          ),
    );
  }

  // Prompt user to pick an existing folder or create a new one,
  // then move all currently‐selected pins out of “All Locations” into that folder.
  void _createFolderAndAssign() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("New Folder"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Folder name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty && !_boardNames.contains(name)) {
                    // Grab all “All Locations” pins and move the selected ones into the new folder.
                    final allPins = ImportService.instance.importedLocations;
                    setState(() {
                      _boardNames.add(name);
                      _customBoards[name] = [];
                      for (var idx in _selectedIndices) {
                        if (idx >= 0 && idx < allPins.length) {
                          _customBoards[name]!.add(allPins[idx]);
                        }
                      }
                      _selectedIndices.clear();
                      _isSelectionMode = false;
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text("Create"),
              ),
            ],
          ),
    );
  }

  // Show a dialog listing existing boards. If user picks one, move selected pins there.
  void _addToFolder() {
    final folderNames = _boardNames;
    showDialog(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text("Select Folder"),
            children: [
              ...folderNames.map((fname) {
                return SimpleDialogOption(
                  onPressed: () {
                    if (fname != "All Locations" &&
                        _customBoards.containsKey(fname)) {
                      final allPins = ImportService.instance.importedLocations;
                      setState(() {
                        for (var idx in _selectedIndices) {
                          if (idx >= 0 && idx < allPins.length) {
                            _customBoards[fname]!.add(allPins[idx]);
                          }
                        }
                        _selectedIndices.clear();
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: Text(fname),
                );
              }),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _createFolderAndAssign();
                },
                child: const Text("Create New Folder"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build a map of “board name → list of pins.”  “All Locations” always
    // points to the ImportService’s master importedLocations list.
    final Map<String, List<Map<String, dynamic>>> folders = {
      "All Locations": ImportService.instance.importedLocations,
      ..._customBoards,
    };
    final boardNames = folders.keys.toList();

    return DefaultTabController(
      length: boardNames.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          title: const Text("Your saved imports"),
          actions: [
            // “Select” button toggles selection mode on or off
            TextButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) _selectedIndices.clear();
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: Text(_isSelectionMode ? "Cancel" : "Select"),
            ),
            // “+” button to create a brand‐new folder
            TextButton(
              onPressed: _showCreateFolderDialog,
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text("+", style: TextStyle(fontSize: 24)),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.black,
            tabs:
                boardNames.map((name) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name),
                        const SizedBox(width: 4),
                        if (folders[name]!.isNotEmpty)
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black26,
                            child: Text(
                              folders[name]!.length.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),

        body: TabBarView(
          children:
              boardNames.map((board) {
                final pinList = folders[board]!;

                // 1) Build a “filtered” list of pins based on _appliedFilters
                final filteredPins =
                    _appliedFilters.isEmpty
                        ? pinList
                        : pinList.where((pin) {
                          final cityLc =
                              (pin['city'] as String? ?? '').toLowerCase();
                          final countryLc =
                              (pin['country'] as String? ?? '').toLowerCase();
                          return _appliedFilters.any((f) {
                            final lower = f.toLowerCase();
                            return cityLc.contains(lower) ||
                                countryLc.contains(lower);
                          });
                        }).toList();

                // NEW: build tags from only city & country
                final tagSet = <String>{};
                for (var pin in pinList) {
                  final city = (pin['city'] as String? ?? '').trim();
                  final country = (pin['country'] as String? ?? '').trim();
                  if (city.isNotEmpty) tagSet.add(city);
                  if (country.isNotEmpty) tagSet.add(country);
                }
                final allTags = tagSet.toList();

                // If this board has no pins at all, show a “empty” message.
                if (pinList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pins in this board yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Otherwise, show a Column that contains:
                //  (a) a horizontal row of ChoiceChips for allTags
                //  (b) a MasonryGridView of the *filteredPins*
                return Column(
                  children: [
                    // ───────────────────────────────────────────────
                    //  (a) Filter row of horizontal ChoiceChips
                    // ───────────────────────────────────────────────
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: allTags.length,
                        itemBuilder: (context, tagIndex) {
                          final tag = allTags[tagIndex];
                          final selected = _appliedFilters.contains(tag);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                              selected: selected,
                              selectedColor: const Color(0xFF062D40),
                              backgroundColor: Colors.grey[200],
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _appliedFilters.add(tag);
                                  } else {
                                    _appliedFilters.remove(tag);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // ───────────────────────────────────────────────
                    //  (b) Grid of filtered pins
                    // ───────────────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MasonryGridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          itemCount: filteredPins.length,
                          itemBuilder: (context, index) {
                            final pin = filteredPins[index];
                            final pinName = pin['name'] as String? ?? 'Unknown';
                            final pinAddress = pin['address'] as String? ?? '';
                            double? lat;
                            double? lng;
                            try {
                              lat = (pin['lat'] as num).toDouble();
                              lng = (pin['lng'] as num).toDouble();
                            } catch (_) {
                              lat = null;
                              lng = null;
                            }

                            final isSelectable =
                                _isSelectionMode &&
                                (board == "All Locations") &&
                                _appliedFilters.isEmpty;
                            final isSelected =
                                isSelectable &&
                                _selectedIndices.contains(index);

                            return Stack(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (isSelectable) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedIndices.remove(index);
                                        } else {
                                          _selectedIndices.add(index);
                                        }
                                      });
                                    } else if (!_isSelectionMode) {
                                      // Tapping a pin navigates to map with only that single pin
                                      if (lat != null && lng != null) {
                                        debugPrint(
                                          "Navigating to map with: $lat, $lng",
                                        );
                                        ImportService.instance.clearAll();
                                        ImportService.instance.addLocations([
                                          {
                                            'name': pinName,
                                            'address': pinAddress,
                                            'lat': lat,
                                            'lng': lng,
                                          },
                                        ]);
                                        try {
                                          Navigator.pushNamed(context, '/map');
                                        } catch (e, stack) {
                                          debugPrint("Navigation error: $e");
                                          debugPrint("Stack trace: $stack");
                                        }
                                      } else {
                                        debugPrint(
                                          "Lat/Lng is null, cannot navigate to map.",
                                        );
                                      }
                                    }
                                  },
                                  child: Card(
                                    color:
                                        isSelected
                                            ? Colors.blue[100]
                                            : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Placeholder thumbnail box
                                          Container(
                                            height: 100,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.play_circle_outline,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            pinName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pinAddress,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          if (lat != null && lng != null)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                const Icon(Icons.map, size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // If we are in “select” mode on “All Locations”, show a checkbox
                                if (isSelectable)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedIndices.add(index);
                                          } else {
                                            _selectedIndices.remove(index);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),

        // If selection mode is active and user has picked at least one pin, show the “Add to Folder” button
        bottomNavigationBar:
            (_isSelectionMode && _selectedIndices.isNotEmpty)
                ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _addToFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text("Add Selected to Folder"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF062D40),
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
                : null,
      ),
    );
  }
}
