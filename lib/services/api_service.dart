import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Small helper to choose the correct base URL per environment.
/// - iOS Simulator & macOS: Cloud Run by default
/// - Android Emulator: 10.0.2.2
/// - Web: 127.0.0.1
///
/// When you deploy to Cloud Run, pass your HTTPS base to [ApiService]'s
/// constructor: `ApiService(baseUrl: 'https://<your-service>.run.app')`.
String get _defaultBaseUrl {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'https://away-backend-975056194033.us-central1.run.app';
}

String _errorDetail(http.Response res) {
  try {
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['detail'] != null) {
      return decoded['detail'].toString();
    }
  } catch (_) {}
  return res.body;
}

class ApiService {
  ApiService({String? baseUrl}) : _base = baseUrl ?? _defaultBaseUrl;

  /// Base URL for the backend. Example values:
  ///  - Local (iOS sim):  http://127.0.0.1:8000
  ///  - Local (Android):  http://10.0.2.2:8000
  ///  - Cloud Run:        https://YOUR-SERVICE-XYZ.a.run.app
  final String _base;

  /// POST /api/parse_instagram_post
  /// body: { "url": "https://www.instagram.com/reel/..." }
  Future<Map<String, dynamic>> parseInstagramUrl(String url) async {
    final uri = Uri.parse('$_base/api/parse_instagram_post');
    debugPrint('➡️ POST $uri');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(const Duration(seconds: 90));

      debugPrint('⬅️ ${res.statusCode} ${res.reasonPhrase}');
      debugPrint('⬅️ Body: ${res.body}');

      if (res.statusCode != 200) {
        throw Exception(_errorDetail(res));
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ parseInstagramUrl error: $e');
      rethrow;
    }
  }

  /// POST /api/geocode_address
  /// body: { "address": "Oia, Greece" }
  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    final uri = Uri.parse('$_base/api/geocode_address');
    debugPrint('➡️ POST $uri');
    try {
      final res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'address': address}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('⬅️ ${res.statusCode} ${res.reasonPhrase}');
      debugPrint('⬅️ Body: ${res.body}');

      if (res.statusCode != 200) {
        throw Exception(_errorDetail(res));
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ geocodeAddress error: $e');
      rethrow;
    }
  }

  /// GET /api/places_autocomplete?query=...
  /// Falls back to geocoding if the autocomplete route is not deployed yet.
  Future<List<Map<String, dynamic>>> autocompletePlaces({
    required String query,
    String? sessionToken,
  }) async {
    final cleaned = query.trim();
    if (cleaned.length < 2) return const [];

    final uri = Uri.parse('$_base/api/places_autocomplete').replace(
      queryParameters: {
        'query': cleaned,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'session_token': sessionToken,
      },
    );
    debugPrint('➡️ GET $uri');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('⬅️ ${res.statusCode} ${res.reasonPhrase}');

      if (res.statusCode == 404) {
        return _geocodeAsSuggestions(cleaned);
      }
      if (res.statusCode != 200) {
        throw Exception(_errorDetail(res));
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = data['suggestions'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      debugPrint('❌ autocompletePlaces error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _geocodeAsSuggestions(String query) async {
    final data = await geocodeAddress(query);
    final rawResults = data['results'];
    final items =
        rawResults is List && rawResults.isNotEmpty
            ? rawResults.whereType<Map>().toList()
            : [data];
    return items.map((item) {
      final address = (item['address'] ?? query).toString();
      final name = (item['name'] ?? query).toString();
      return <String, dynamic>{
        'place_id': item['place_id'],
        'primary_text': name,
        'secondary_text': address,
        'description': address,
        'lat': item['lat'],
        'lng': item['lng'],
        'city': item['city'],
        'country': item['country'],
        'address': address,
        'name': name,
      };
    }).toList();
  }

  /// GET /api/place_details?place_id=...
  Future<Map<String, dynamic>> placeDetails({
    required String placeId,
    String? sessionToken,
  }) async {
    final uri = Uri.parse('$_base/api/place_details').replace(
      queryParameters: {
        'place_id': placeId,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'session_token': sessionToken,
      },
    );
    debugPrint('➡️ GET $uri');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('⬅️ ${res.statusCode} ${res.reasonPhrase}');
      if (res.statusCode != 200) {
        throw Exception(_errorDetail(res));
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ placeDetails error: $e');
      rethrow;
    }
  }

  /// Best-effort thumbnail resolver for Instagram post URLs.
  /// Uses noembed as a public fallback when backend does not return thumbnail data.
  Future<String?> tryFetchInstagramThumbnail(String url) async {
    final uri = Uri.parse(
      'https://noembed.com/embed?url=${Uri.encodeComponent(url)}',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final thumb = (data['thumbnail_url'] ?? data['thumbnailUrl'])?.toString();
      if (thumb == null || thumb.isEmpty) return null;
      return thumb;
    } catch (_) {
      return null;
    }
  }
}
