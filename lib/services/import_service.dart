/// An in‐memory singleton that holds all imported locations
/// (each location is a Map<String, dynamic> containing keys
/// 'name', 'address', 'lat', and 'lng').

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImportService extends ChangeNotifier {
  // private constructor
  ImportService._();

  // the single, global instance
  static final ImportService instance = ImportService._();

  static const allFolderName = 'All Locations';

  // internal list of all imported location maps
  final List<Map<String, dynamic>> _importedLocations = [];

  final List<String> _folderNames = [allFolderName, 'Lisbon', 'Food'];
  final Map<String, List<Map<String, dynamic>>> _folderPins = {
    'Lisbon': [],
    'Food': [],
  };

  CollectionReference<Map<String, dynamic>>? get _importsCollection {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('imports');
  }

  String _docIdFor(Map<String, dynamic> loc) {
    final name = (loc['name'] ?? '').toString().trim();
    final lat = loc['lat'] ?? loc['latitude'] ?? '';
    final lng = loc['lng'] ?? loc['longitude'] ?? '';
    final key = '${name}_${lat}_${lng}';
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String? _extractInstagramShortcode(String url) {
    final match = RegExp(
      r'(?:/reel/|/p/|/tv/)([A-Za-z0-9_-]{5,})',
    ).firstMatch(url);
    return match?.group(1);
  }

  /// Returns a read‐only view of all imported locations.
  List<Map<String, dynamic>> get importedLocations =>
      List.unmodifiable(_importedLocations);

  List<String> get folderNames => List.unmodifiable(_folderNames);

  List<String> get customFolderNames =>
      _folderNames.where((name) => name != allFolderName).toList();

  List<Map<String, dynamic>> pinsInFolder(String folder) {
    if (folder == allFolderName) return importedLocations;
    return List.unmodifiable(_folderPins[folder] ?? const []);
  }

  bool createFolder(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _folderNames.contains(trimmed)) return false;
    _folderNames.add(trimmed);
    _folderPins[trimmed] = [];
    notifyListeners();
    return true;
  }

  void addPinsToFolder(String folder, Iterable<Map<String, dynamic>> pins) {
    if (folder == allFolderName) return;
    final list = _folderPins.putIfAbsent(folder, () {
      if (!_folderNames.contains(folder)) _folderNames.add(folder);
      return <Map<String, dynamic>>[];
    });
    for (final pin in pins) {
      final already = list.any((existing) => _samePin(existing, pin));
      if (!already) list.add(Map<String, dynamic>.from(pin));
    }
    notifyListeners();
  }

  bool _samePin(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a['name'] == b['name'] &&
        a['lat'] == b['lat'] &&
        a['lng'] == b['lng'];
  }

  void _removePinFromFolders(Map<String, dynamic> loc) {
    for (final list in _folderPins.values) {
      list.removeWhere((item) => _samePin(item, loc));
    }
  }

  /// a batch of new locations. If a location with the same 'name'
  /// and identical lat/lng already exists, it won’t be added again.
  void addLocations(List<Map<String, dynamic>> newOnes) {
    for (var loc in newOnes) {
      final name = loc['name'];
      final lat = loc['lat'] ?? loc['latitude'];
      final lng = loc['lng'] ?? loc['longitude'];
      final alreadyExists = _importedLocations.any(
        (e) => e['name'] == name && e['lat'] == lat && e['lng'] == lng,
      );
      if (!alreadyExists) {
        _importedLocations.add({
          'name': name,
          'address': loc['address'],
          'city': loc['city'],
          'country': loc['country'],
          'lat': lat,
          'lng': lng,
          'videoUrl': loc['videoUrl'] ?? loc['video_url'],
          'thumbnailUrl': loc['thumbnailUrl'] ?? loc['thumbnail_url'],
          'thumbnailStoragePath':
              loc['thumbnailStoragePath'] ?? loc['thumbnail_storage_path'],
          'sourceUrl': loc['sourceUrl'] ?? loc['source_url'] ?? loc['source'],
          'caption': loc['caption'],
          'createdAt': loc['createdAt'],
        });
      }
    }
    notifyListeners();
  }

  Future<void> addAndPersistLocations(
    List<Map<String, dynamic>> newOnes,
  ) async {
    addLocations(newOnes);

    final imports = _importsCollection;
    if (imports == null) return;

    final now = FieldValue.serverTimestamp();
    for (final loc in newOnes) {
      final lat = loc['lat'] ?? loc['latitude'];
      final lng = loc['lng'] ?? loc['longitude'];
      final normalized = <String, dynamic>{
        'name': loc['name'],
        'address': loc['address'],
        'city': loc['city'],
        'country': loc['country'],
        'lat': lat,
        'lng': lng,
        'videoUrl': loc['videoUrl'] ?? loc['video_url'],
        'thumbnailUrl': loc['thumbnailUrl'] ?? loc['thumbnail_url'],
        'thumbnailStoragePath':
            loc['thumbnailStoragePath'] ?? loc['thumbnail_storage_path'],
        'sourceUrl': loc['sourceUrl'] ?? loc['source_url'] ?? loc['source'],
        'caption': loc['caption'],
        'updatedAt': now,
      };

      await imports.doc(_docIdFor(normalized)).set({
        ...normalized,
        'createdAt': now,
      }, SetOptions(merge: true));
    }
  }

  Future<void> loadFromFirestore() async {
    final imports = _importsCollection;
    if (imports == null) return;

    final snapshot = await imports.orderBy('updatedAt', descending: true).get();
    final loaded =
        snapshot.docs.map((d) {
          final data = d.data();
          return <String, dynamic>{
            'docId': d.id,
            'name': data['name'],
            'address': data['address'],
            'city': data['city'],
            'country': data['country'],
            'lat': data['lat'],
            'lng': data['lng'],
            'videoUrl': data['videoUrl'] ?? data['sourceUrl'],
            'thumbnailUrl': data['thumbnailUrl'],
            'thumbnailStoragePath': data['thumbnailStoragePath'],
            'sourceUrl': data['sourceUrl'],
            'caption': data['caption'],
            'createdAt': data['createdAt'],
          };
        }).toList();

    // Backfill thumbnail URL for older records that have a link but no thumbnail.
    for (final item in loaded) {
      final existingThumb = (item['thumbnailUrl'] as String? ?? '').trim();
      if (existingThumb.isNotEmpty) continue;

      final storagePath =
          (item['thumbnailStoragePath'] as String? ?? '').trim();
      if (storagePath.isNotEmpty) {
        try {
          final downloadUrl =
              await FirebaseStorage.instance.ref(storagePath).getDownloadURL();
          if (downloadUrl.isNotEmpty) {
            item['thumbnailUrl'] = downloadUrl;
            final docId = (item['docId'] as String?)?.trim();
            if (docId != null && docId.isNotEmpty) {
              await imports.doc(docId).set({
                'thumbnailUrl': downloadUrl,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
            continue;
          }
        } catch (_) {
          // Keep fallback strategy below.
        }
      }

      final videoUrl = (item['videoUrl'] as String? ?? '').trim();
      if (videoUrl.isEmpty) continue;

      final fetchedThumb = await _tryFetchInstagramThumbnail(videoUrl);
      if (fetchedThumb == null || fetchedThumb.isEmpty) continue;

      item['thumbnailUrl'] = fetchedThumb;
      final docId = (item['docId'] as String?)?.trim();
      if (docId != null && docId.isNotEmpty) {
        await imports.doc(docId).set({
          'thumbnailUrl': fetchedThumb,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    _importedLocations
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<String?> _tryFetchInstagramThumbnail(String url) async {
    final uri = Uri.parse(
      'https://noembed.com/embed?url=${Uri.encodeComponent(url)}',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final thumb = (data['thumbnail_url'] ?? data['thumbnailUrl'])?.toString();
      if (thumb == null || thumb.isEmpty) return null;
      return thumb;
    } catch (_) {
      return null;
    }
  }

  void _resetFolders() {
    _folderNames
      ..clear()
      ..addAll([allFolderName, 'Lisbon', 'Food']);
    _folderPins
      ..clear()
      ..addAll({
        'Lisbon': <Map<String, dynamic>>[],
        'Food': <Map<String, dynamic>>[],
      });
  }

  /// clear all stored locations (if you ever need to reset).
  void clearAll() {
    _importedLocations.clear();
    _resetFolders();
    notifyListeners();
  }

  /// Deletes persisted imports, then clears in-memory state.
  Future<void> deleteAllPersisted() async {
    final imports = _importsCollection;
    if (imports != null) {
      final snapshot = await imports.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
    _importedLocations.clear();
    _resetFolders();
    notifyListeners();
  }

  Future<void> deleteLocation(Map<String, dynamic> loc) async {
    _importedLocations.removeWhere((e) => _samePin(e, loc));
    _removePinFromFolders(loc);
    final imports = _importsCollection;
    if (imports == null) return;
    final docId = (loc['docId'] as String?)?.trim();
    if (docId != null && docId.isNotEmpty) {
      await imports.doc(docId).delete();
    } else {
      await imports.doc(_docIdFor(loc)).delete();
    }
    notifyListeners();
  }

  bool isDuplicateUrl(String url) {
    final trimmed = url.trim();
    final incomingShortcode = _extractInstagramShortcode(trimmed);
    return _importedLocations.any((loc) {
      final sourceUrl = (loc['sourceUrl'] as String? ?? '').trim();
      if (sourceUrl == trimmed) {
        return true;
      }
      if (incomingShortcode == null) {
        return false;
      }
      final existingShortcode = _extractInstagramShortcode(sourceUrl);
      return existingShortcode != null &&
          existingShortcode == incomingShortcode;
    });
  }
}
