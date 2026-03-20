import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:away/services/import_service.dart';

class ImportPostScreen extends StatelessWidget {
  final Map<String, dynamic> pin;

  const ImportPostScreen({super.key, required this.pin});

  Future<void> _openOriginalVideo(BuildContext context, String? rawUrl) async {
    final url = (rawUrl ?? '').trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No original video link available yet.')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    final isValid =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This video link is invalid.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Instagram link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (pin['name'] as String? ?? 'Imported Post').trim();
    final address = (pin['address'] as String? ?? '').trim();
    final caption = (pin['caption'] as String? ?? '').trim();
    final videoUrl =
        ((pin['videoUrl'] as String?)?.trim().isNotEmpty ?? false)
            ? (pin['videoUrl'] as String).trim()
            : (pin['sourceUrl'] as String? ?? '').trim();
    final thumbUrl = (pin['thumbnailUrl'] as String? ?? '').trim();
    final hasThumb =
        thumbUrl.isNotEmpty &&
        (thumbUrl.startsWith('http://') || thumbUrl.startsWith('https://'));

    final latValue = pin['lat'];
    final lngValue = pin['lng'];
    final lat = latValue is num ? latValue.toDouble() : null;
    final lng = lngValue is num ? lngValue.toDouble() : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          name.isEmpty ? 'Saved Import' : name,
          style: const TextStyle(
            color: Color(0xFF062D40),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF062D40)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (hasThumb)
                            Image.network(
                              thumbUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 34,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              color: Colors.grey[300],
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image,
                                size: 34,
                                color: Colors.grey,
                              ),
                            ),
                          Container(color: Colors.black.withAlpha(55)),
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      style: const TextStyle(
                        color: Color(0xFF062D40),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (address.isNotEmpty) const SizedBox(height: 12),
                  const Text(
                    'Parsed Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF062D40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      caption.isEmpty
                          ? 'No parsed description was saved for this import.'
                          : caption,
                      style: const TextStyle(height: 1.35, fontSize: 14),
                    ),
                  ),
                  if (lat != null && lng != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ImportService.instance.clearAll();
                        ImportService.instance.addLocations([
                          {
                            'name': name,
                            'address': address,
                            'lat': lat,
                            'lng': lng,
                          },
                        ]);
                        Navigator.pushNamed(
                          context,
                          '/map',
                          arguments: {
                            'fromImports': true,
                            'showBackToImportButton': true,
                          },
                        );
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('View on map'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openOriginalVideo(context, videoUrl),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open original Instagram link'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF062D40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
