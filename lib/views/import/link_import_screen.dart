// lib/views/import/link_import_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../import/link_import_success_screen.dart';
import 'package:away/services/api_service.dart';

class ImportLinkScreen extends StatefulWidget {
  const ImportLinkScreen({super.key});

  @override
  State<ImportLinkScreen> createState() => _ImportLinkScreenState();
}

class _ImportLinkScreenState extends State<ImportLinkScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // New fields for clipboard and progress
  String? _clipboardUrl;
  double _progress = 0.0;
  Timer? _progressTimer;
  final RegExp _igRegex = RegExp(r'https?://(www\.)?instagram\.com/\S+');

  @override
  void initState() {
    super.initState();
    _primeClipboard();
    _urlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _primeClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text?.trim();
      if (text != null && _igRegex.hasMatch(text)) {
        setState(() => _clipboardUrl = text);
      }
    } catch (_) {}
  }

  void _startFakeProgress() {
    _progressTimer?.cancel();
    setState(() => _progress = 0.0);
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      // creep to 90% while waiting; completion will set to 100
      if (!mounted) return;
      setState(() {
        _progress = (_progress + 0.03).clamp(0.0, 0.9);
      });
    });
  }

  void _stopProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
    if (mounted) setState(() => _progress = 1.0);
    // brief delay so users see 100%
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _progress = 0.0);
    });
  }

  Future<void> _handleImport() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !_igRegex.hasMatch(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a valid Instagram link.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _startFakeProgress();
    try {
      final result = await _apiService.parseInstagramUrl(url);
      final caption = result['caption'] as String;
      final locList = result['locations'] as List<dynamic>;

      final locations =
          locList.map((loc) {
            return {
              'name': loc['name'],
              'address': loc['address'],
              'city': loc['city'],
              'country': loc['country'],
              'latitude': loc['lat'],
              'longitude': loc['lng'],
            };
          }).toList();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  ImportSuccessScreen(caption: caption, locations: locations),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Import failed: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _stopProgress();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF062D40);
    final bool canImport =
        _igRegex.hasMatch(_urlController.text.trim()) && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Import Video',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Paste your Instagram link below',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We\'ll extract any places mentioned and place them on your map!',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                // URL Input Field
                Material(
                  elevation: 1,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "https://www.instagram.com/...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        color: Colors.black54,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_urlController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close_rounded),
                              onPressed:
                                  () => setState(() => _urlController.clear()),
                            ),
                          TextButton(
                            onPressed: () async {
                              if (_clipboardUrl == null)
                                await _primeClipboard();
                              if (_clipboardUrl != null) {
                                setState(
                                  () => _urlController.text = _clipboardUrl!,
                                );
                              }
                            },
                            child: const Text('Paste'),
                          ),
                        ],
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 1.5),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
                if (_clipboardUrl != null && _urlController.text.isEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed:
                          () => setState(
                            () => _urlController.text = _clipboardUrl!,
                          ),
                      icon: const Icon(Icons.content_paste_rounded, size: 18),
                      label: const Text('Paste from clipboard'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: canImport ? _handleImport : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(_progress * 100).clamp(0, 100).round()}%  Parsing…',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            'Import',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress == 0.0 ? null : _progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We\'re parsing your link…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
