import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:away/services/import_service.dart';

class MyImportsScreen extends StatefulWidget {
  const MyImportsScreen({super.key});

  @override
  State<MyImportsScreen> createState() => _MyImportsScreenState();
}

class _MyImportsScreenState extends State<MyImportsScreen> {
  final List<String> _boardNames = ["All Locations"];
  final Map<String, List<Map<String, dynamic>>> _customBoards = {};

  String _selectedBoard = "All Locations";

  final Set<int> _selectedIndices = {};

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

  Widget _buildBoardContent(String board) {
    // Build a map of “board name → list of pins.”  “All Locations” always
    // points to the ImportService’s master importedLocations list.
    final Map<String, List<Map<String, dynamic>>> folders = {
      "All Locations": ImportService.instance.importedLocations,
      ..._customBoards,
    };
    final pinList = folders[board]!;
    final filteredPins =
        _appliedFilters.isEmpty
            ? pinList
            : pinList.where((pin) {
              final cityLc = (pin['city'] as String? ?? '').toLowerCase();
              final countryLc = (pin['country'] as String? ?? '').toLowerCase();
              return _appliedFilters.any((f) {
                final lower = f.toLowerCase();
                return cityLc.contains(lower) || countryLc.contains(lower);
              });
            }).toList();

    final tagSet = <String>{};
    for (var pin in pinList) {
      final city = (pin['city'] as String? ?? '').trim();
      final country = (pin['country'] as String? ?? '').trim();
      if (city.isNotEmpty) tagSet.add(city);
      if (country.isNotEmpty) tagSet.add(country);
    }
    final allTags = tagSet.toList();

    if (pinList.isEmpty) {
      return const Center(
        child: Text(
          'No pins in this board yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
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
                      color: selected ? Colors.white : Color(0xFF062D40),
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              itemCount: filteredPins.length,
              itemBuilder: (context, index) {
                // existing pin rendering code...
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
                    isSelectable && _selectedIndices.contains(index);

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
                            debugPrint("Navigating to map with: $lat, $lng");
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
                              Navigator.pushNamed(
                                context,
                                '/map',
                                arguments: {
                                  'fromImports': true,
                                  // 'showDoneButton': true,
                                  'showBackToImportButton': true,
                                },
                              );
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
                        color: isSelected ? Colors.blue[100] : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Placeholder thumbnail box
                              Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
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
                                  color: Color(0xFF062D40),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (lat != null && lng != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.map, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 12),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'My Imports',
          style: TextStyle(
            color: Color(0xFF062D40),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Color(0xFF062D40)),
            onPressed: () {
              // TODO: implement bookmark functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF062D40)),
            onPressed: () {
              // TODO: implement share functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search your saved imports…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = !_isSelectionMode;
                      if (!_isSelectionMode) _selectedIndices.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF062D40),
                  ),
                  child: Text(_isSelectionMode ? 'Cancel' : 'Select'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF062D40),
                  ),
                  icon: const Icon(Icons.sort),
                  label: const Text('Sort'),
                ),
              ],
            ),
          ),
          // Folder tabs (like TabBar)
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 0,
                runSpacing: 0,
                children:
                    _boardNames.map((name) {
                      final isSelected = _selectedBoard == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Color(0xFF062D40),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Color(0xFF062D40),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? Color(0xFF062D40)
                                      : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedBoard = name;
                            });
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          // Content: Show selected board
          Expanded(child: _buildBoardContent(_selectedBoard)),
        ],
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
    );
  }
}
