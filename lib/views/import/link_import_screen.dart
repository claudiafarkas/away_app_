import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../import/link_import_success_screen.dart';
import 'package:away/services/api_service.dart';
import 'package:away/services/import_service.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/widgets/soft_tile.dart';

class ImportLinkScreen extends StatefulWidget {
  final String? initialUrl;

  const ImportLinkScreen({super.key, this.initialUrl});

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

  String _normalizeInstagramUrl(String url) {
    final parsed = Uri.tryParse(url.trim());
    if (parsed == null) return url.trim();
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      path: parsed.path,
    ).toString();
  }

  @override
  void initState() {
    super.initState();
    // Removed automatic clipboard reading on init - will only happen when user taps paste button
    _urlController.addListener(() => setState(() {}));
    final initialUrl = widget.initialUrl?.trim();
    if (initialUrl != null && initialUrl.isNotEmpty) {
      _urlController.text = initialUrl;
    }
  }

  @override
  void didUpdateWidget(covariant ImportLinkScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.initialUrl?.trim() ?? '';
    final next = widget.initialUrl?.trim() ?? '';
    if (next.isNotEmpty && next != previous) {
      _urlController.text = next;
    }
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
    final rawInput = _urlController.text.trim();
    // Extract the first valid Instagram URL from the input
    final match = _igRegex.firstMatch(rawInput);
    final url = _normalizeInstagramUrl(match?.group(0) ?? '');
    debugPrint('✅ Cleaned URL: "$url"');
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a valid Instagram link.')),
      );
      debugPrint('❌ Invalid or empty URL: "$url"');
      return;
    }

    debugPrint('📤 Sending raw input: "$rawInput"');
    debugPrint('📤 Sending cleaned URL to API: "$url"');

    // Duplicate check
    if (ImportService.instance.isDuplicateUrl(url)) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Already Imported!'),
              content: const Text(
                "Oops! You've already imported this video. Try another one!",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    setState(() => _isLoading = true);
    _startFakeProgress();
    try {
      final result = await _apiService.parseInstagramUrl(url);
      final caption = result['caption'] as String;
      final videoUrl =
          ((result['videoUrl'] ?? result['video_url'] ?? result['url'])
                      ?.toString()
                      .trim()
                      .isNotEmpty ??
                  false)
              ? (result['videoUrl'] ?? result['video_url'] ?? result['url'])
                  .toString()
                  .trim()
              : url;
      String? thumbnailUrl =
          (result['thumbnailUrl'] ??
                  result['thumbnail_url'] ??
                  result['thumbnail'])
              ?.toString()
              .trim();
      final thumbnailStoragePath =
          (result['thumbnailStoragePath'] ?? result['thumbnail_storage_path'])
              ?.toString()
              .trim();
      if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
        thumbnailUrl = await _apiService.tryFetchInstagramThumbnail(url);
      }
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
              (_) => ImportSuccessScreen(
                caption: caption,
                locations: locations,
                videoUrl: videoUrl,
                thumbnailUrl: thumbnailUrl,
                thumbnailStoragePath: thumbnailStoragePath,
                sourceUrl: url,
              ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Exception during import: $e');
      final isRateLimited = e.toString().contains("Please wait a few minutes");
      debugPrint('❌ Full URL at failure: "$url"');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRateLimited
                  ? "Instagram temporarily blocked requests. Try again in a few minutes."
                  : "⚠️ Import failed: $e",
            ),
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
    final bool canImport =
        _igRegex.hasMatch(_urlController.text.trim()) && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 128),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              SoftTile(
                gradient: AppColors.featuredGradients[1],
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Instagram to map pins',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.inkDeep,
                          size: 20,
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Drop a video link. Away extracts locations and lays them onto your map.',
                      style: TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftTile(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'https://www.instagram.com/...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    prefixIcon: const Icon(
                      Icons.link_rounded,
                      color: AppColors.muted,
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
                            if (_clipboardUrl == null) await _primeClipboard();
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
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              if (_clipboardUrl != null && _urlController.text.isEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed:
                        () =>
                            setState(() => _urlController.text = _clipboardUrl!),
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: const Text('Paste from clipboard'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: canImport ? _handleImport : null,
                child:
                    _isLoading
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
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
                        : const Text('Import'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/manual_import_screen',
                          );
                          if (!mounted || result == null) return;
                          final pin = Map<String, dynamic>.from(result as Map);
                          final name = (pin['name'] ?? 'Place').toString();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved $name to your map')),
                          );
                        },
                icon: const Icon(Icons.edit_location_alt_rounded),
                label: const Text('Add a place manually'),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress == 0.0 ? null : _progress,
                    minHeight: 8,
                    backgroundColor: AppColors.sky,
                    color: AppColors.inkDeep,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Parsing your link…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
