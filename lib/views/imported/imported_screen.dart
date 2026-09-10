import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:away/services/import_service.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/views/imported/import_post_screen.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/pin_card.dart';
import 'package:away/widgets/soft_tile.dart';

class MyImportsScreen extends StatefulWidget {
  const MyImportsScreen({super.key});

  @override
  State<MyImportsScreen> createState() => _MyImportsScreenState();
}

class _MyImportsScreenState extends State<MyImportsScreen> {
  final List<String> _boardNames = ["All Locations", "Lisbon", "Food"];
  final Map<String, List<Map<String, dynamic>>> _customBoards = {
    "Lisbon": [],
    "Food": [],
  };

  String _selectedBoard = "All Locations";

  final Set<int> _selectedIndices = {};

  bool _isSelectionMode = false;

  /// Which text‐based “tags” (city/country/name/address‐fragments) are currently applied
  final Set<String> _appliedFilters = {};

  bool _isLoadingImports = true;

  @override
  void initState() {
    super.initState();
    _loadPersistedImports();
  }

  Future<void> _loadPersistedImports() async {
    setState(() => _isLoadingImports = true);
    try {
      await ImportService.instance.loadFromFirestore();
    } catch (e) {
      debugPrint('Failed to load imports from Firestore: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingImports = false);
      }
    }
  }

  void _promptNewFolder() {
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
                      _selectedBoard = name;
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

  void _deletePin(Map<String, dynamic> pin) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Import'),
            content: const Text('Are you sure you want to remove this import?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ImportService.instance.deleteLocation(pin);
                  if (mounted) {
                    setState(() {
                      for (final board in _customBoards.values) {
                        board.removeWhere(
                          (item) =>
                              item['name'] == pin['name'] &&
                              item['lat'] == pin['lat'] &&
                              item['lng'] == pin['lng'],
                        );
                      }
                    });
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Widget _buildBoardContent(String board) {
    if (_isLoadingImports) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.inkDeep),
      );
    }

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
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return Column(
      children: [
        if (allTags.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allTags.length,
              itemBuilder: (context, tagIndex) {
                final tag = allTags[tagIndex];
                final selected = _appliedFilters.contains(tag);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tag),
                    selected: selected,
                    showCheckmark: false,
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: filteredPins.length,
              itemBuilder: (context, index) {
                final pin = filteredPins[index];
                final pinName = pin['name'] as String? ?? 'Unknown';
                final pinAddress = pin['address'] as String? ?? '';
                final thumbUrl = (pin['thumbnailUrl'] as String? ?? '').trim();
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
                    PinCard(
                      name: pinName,
                      address: pinAddress,
                      thumbUrl: thumbUrl,
                      lat: lat,
                      lng: lng,
                      imageHeight: [128.0, 168.0, 146.0][index % 3],
                      gradientIndex: index,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImportPostScreen(pin: pin),
                            ),
                          );
                        }
                      },
                      overlay:
                          isSelected
                              ? Container(
                                color: AppColors.sky.withValues(alpha: 0.35),
                              )
                              : null,
                    ),
                    if (isSelectable)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              isSelected ? AppColors.inkDeep : Colors.white,
                          child: Icon(
                            isSelected ? Icons.check : Icons.circle_outlined,
                            size: 16,
                            color:
                                isSelected ? Colors.white : AppColors.inkDeep,
                          ),
                        ),
                      ),
                    if (!_isSelectionMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _deletePin(pin),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.ink,
                              size: 16,
                            ),
                          ),
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
    return CloudScaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('My Imports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: GlassPill(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.muted),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search saved imports',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  child: Text(_isSelectionMode ? 'Cancel' : 'Select'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._boardNames.map((name) {
                  final isSelected = _selectedBoard == name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _selectedBoard = name;
                        });
                      },
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Folder'),
                    onPressed: _promptNewFolder,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBoardContent(_selectedBoard)),
        ],
      ),
      bottomNavigationBar:
          (_isSelectionMode && _selectedIndices.isNotEmpty)
              ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ElevatedButton.icon(
                    onPressed: _addToFolder,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Add selected to folder'),
                  ),
                ),
              )
              : null,
    );
  }
}
