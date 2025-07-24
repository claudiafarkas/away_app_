import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  final _base = "http://localhost:8000"; // Use this for local development
  // final _base = "http://0.0.0.0:8000";
  Future<Map<String, dynamic>> parseInstagramUrl(String url) async {
    final res = await http.post(
      Uri.parse("$_base/parse_instagram_post"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );
    debugPrint("🔍 [ApiService] Status: ${res.statusCode}");
    debugPrint("🔍 [ApiService] Body: ${res.body}");
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to parse: ${res.body}");
    }
  }
}
