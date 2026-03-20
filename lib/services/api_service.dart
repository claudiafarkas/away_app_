import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Small helper to choose the correct base URL per environment.
/// - iOS Simulator & macOS: 127.0.0.1
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
        throw Exception('Failed to parse: ${res.statusCode} ${res.body}');
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
        throw Exception('Failed to geocode: ${res.statusCode} ${res.body}');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ geocodeAddress error: $e');
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


// api_service.dart


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/foundation.dart';

// class ApiService {
//   final _base = "http://localhost:8000"; // Use this for local development
//   // final _base = "http://0.0.0.0:8000";
//   Future<Map<String, dynamic>> parseInstagramUrl(String url) async {
//     final res = await http.post(
//       Uri.parse("$_base/parse_instagram_post"),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'url': url}),
//     );
//     debugPrint("🔍 [ApiService] Status: ${res.statusCode}");
//     debugPrint("🔍 [ApiService] Body: ${res.body}");
//     if (res.statusCode == 200) {
//       return jsonDecode(res.body) as Map<String, dynamic>;
//     } else {
//       throw Exception("Failed to parse: ${res.body}");
//     }
//   }
// }

