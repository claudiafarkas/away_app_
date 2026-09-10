import 'dart:async';

import 'package:away/services/api_service.dart';
import 'package:away/services/import_service.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/soft_tile.dart';
import 'package:flutter/material.dart';

class ManualImportScreen extends StatefulWidget {
  const ManualImportScreen({super.key});

  @override
  State<ManualImportScreen> createState() => _ManualImportScreenState();
}

class _ManualImportScreenState extends State<ManualImportScreen> {
  final ApiService _api = ApiService();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _linkController = TextEditingController();
  final _searchFocus = FocusNode();

  Timer? _debounce;
  int _suggestRequestId = 0;
  String _sessionToken = UniqueKey().toString();

  List<Map<String, dynamic>> _suggestions = [];
  bool _suggesting = false;
  bool _saving = false;
  String? _suggestError;
  Map<String, dynamic>? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _nameController.dispose();
    _linkController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _rotateSessionToken() {
    _sessionToken = UniqueKey().toString();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounce?.cancel();
    if (_selectedPlace != null &&
        query == (_selectedPlace!['address'] as String? ?? '')) {
      return;
    }
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _suggesting = false;
        _suggestError = null;
      });
      return;
    }
    setState(() {
      _suggesting = true;
      _suggestError = null;
      _selectedPlace = null;
    });
    _debounce = Timer(const Duration(milliseconds: 180), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    final requestId = ++_suggestRequestId;
    try {
      final results = await _api.autocompletePlaces(
        query: query,
        sessionToken: _sessionToken,
      );
      if (!mounted || requestId != _suggestRequestId) return;
      setState(() {
        _suggestions = results;
        _suggesting = false;
        _suggestError = results.isEmpty ? 'No matching places' : null;
      });
    } catch (e) {
      if (!mounted || requestId != _suggestRequestId) return;
      setState(() {
        _suggestions = [];
        _suggesting = false;
        _suggestError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    setState(() {
      _suggesting = true;
      _suggestError = null;
    });
    try {
      final placeId = (suggestion['place_id'] ?? '').toString().trim();
      Map<String, dynamic> place;
      if (placeId.isNotEmpty) {
        try {
          place = await _api.placeDetails(
            placeId: placeId,
            sessionToken: _sessionToken,
          );
        } catch (_) {
          if (suggestion['lat'] != null && suggestion['lng'] != null) {
            place = suggestion;
          } else {
            place = await _api.geocodeAddress(
              (suggestion['description'] ?? suggestion['primary_text'] ?? '')
                  .toString(),
            );
          }
        }
      } else if (suggestion['lat'] != null && suggestion['lng'] != null) {
        place = suggestion;
      } else {
        place = await _api.geocodeAddress(
          (suggestion['description'] ?? suggestion['primary_text'] ?? '')
              .toString(),
        );
      }

      if (!mounted) return;
      final name =
          (place['name'] ??
                  suggestion['primary_text'] ??
                  _searchController.text)
              .toString();
      final address =
          (place['address'] ?? suggestion['description'] ?? name).toString();
      _searchController.removeListener(_onSearchChanged);
      _searchController.text = address;
      _searchController.addListener(_onSearchChanged);
      _nameController.text = name;
      _rotateSessionToken();
      setState(() {
        _selectedPlace = {
          'name': name,
          'address': address,
          'city': place['city'] ?? suggestion['city'] ?? '',
          'country': place['country'] ?? suggestion['country'] ?? '',
          'lat': place['lat'] ?? suggestion['lat'],
          'lng': place['lng'] ?? suggestion['lng'],
          'place_id': place['place_id'] ?? placeId,
        };
        _suggestions = [];
        _suggesting = false;
      });
      _searchFocus.unfocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggesting = false;
        _suggestError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submitForm() async {
    if (_saving) return;
    var place = _selectedPlace;
    final query = _searchController.text.trim();
    if (place == null) {
      if (query.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search for a place, then tap a suggestion.')),
        );
        return;
      }
      setState(() => _saving = true);
      try {
        place = await _api.geocodeAddress(query);
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    final lat = (place['lat'] as num?)?.toDouble();
    final lng = (place['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That place is missing map coordinates.')),
      );
      return;
    }

    final name =
        _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : (place['name'] ?? query).toString().trim();
    final address = (place['address'] ?? query).toString();
    final city = (place['city'] ?? '').toString();
    final country = (place['country'] ?? '').toString();
    final cityCountry =
        [city, country].where((part) => part.trim().isNotEmpty).join(', ');

    final manualPin = <String, dynamic>{
      'name': name.isEmpty ? address : name,
      'address': address,
      'city': cityCountry.isNotEmpty ? cityCountry : city,
      'country': country,
      'sourceUrl': _linkController.text.trim(),
      'lat': lat,
      'lng': lng,
      'latitude': lat,
      'longitude': lng,
    };

    setState(() => _saving = true);
    try {
      await ImportService.instance.addAndPersistLocations([manualPin]);
      if (!mounted) return;
      Navigator.pop(context, manualPin);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved locally, but sync failed: $e')),
      );
      Navigator.pop(context, manualPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queryText = _searchController.text.trim();
    final showDropdown =
        _selectedPlace == null &&
        queryText.length >= 2 &&
        (_suggestions.isNotEmpty || !_suggesting);

    return CloudScaffold(
      appBar: AppBar(title: const Text('Add a place')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ListView(
          children: [
            SoftTile(
              gradient: AppColors.featuredGradients[2],
              child: const Text(
                'Start typing a place. Tap a suggestion to drop it on your map.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (_suggestions.isNotEmpty) {
                  _selectSuggestion(_suggestions.first);
                } else if (value.trim().length >= 2) {
                  _selectSuggestion({
                    'description': value.trim(),
                    'primary_text': value.trim(),
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Search places',
                hintText: 'Cafe, neighborhood, city, or address',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    _suggesting
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : (_searchController.text.isEmpty
                            ? null
                            : IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _suggestions = [];
                                  _selectedPlace = null;
                                  _suggestError = null;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            )),
              ),
            ),
            if (_suggestError != null) ...[
              const SizedBox(height: 8),
              Text(
                _suggestError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8A4A3A),
                ),
              ),
            ],
            if (showDropdown) ...[
              const SizedBox(height: 8),
              SoftTile(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < _suggestions.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.inkDeep,
                        ),
                        title: Text(
                          (_suggestions[i]['primary_text'] ??
                                  _suggestions[i]['description'] ??
                                  '')
                              .toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        subtitle:
                            ((_suggestions[i]['secondary_text'] ?? '')
                                    .toString()
                                    .isEmpty)
                                ? null
                                : Text(
                                  _suggestions[i]['secondary_text'].toString(),
                                ),
                        onTap: () => _selectSuggestion(_suggestions[i]),
                      ),
                    ],
                    if (queryText.isNotEmpty) ...[
                      if (_suggestions.isNotEmpty) const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.search_rounded,
                          color: AppColors.inkDeep,
                        ),
                        title: Text(
                          'Search for “$queryText”',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        onTap:
                            () => _selectSuggestion({
                              'description': queryText,
                              'primary_text': queryText,
                            }),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_selectedPlace != null) ...[
              const SizedBox(height: 16),
              SoftTile(
                color: AppColors.sky.withValues(alpha: 0.45),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_selectedPlace!['name'] ?? '').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (_selectedPlace!['address'] ?? '').toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pin name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Source link (optional)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submitForm,
                icon:
                    _saving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : 'Save location'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
