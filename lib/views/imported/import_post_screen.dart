import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:away/theme/app_colors.dart';
import 'package:away/widgets/cloud_backdrop.dart';
import 'package:away/widgets/soft_tile.dart';

class ImportPostScreen extends StatelessWidget {
  final Map<String, dynamic> pin;

  const ImportPostScreen({super.key, required this.pin});

  Future<void> _shareImport(
    BuildContext context, {
    required String name,
    required String address,
    required String sourceUrl,
  }) async {
    final cleanName = name.trim();
    final cleanAddress = address.trim();
    final cleanUrl = sourceUrl.trim();

    final message = [
      if (cleanName.isNotEmpty) 'Saved in Away: $cleanName',
      if (cleanAddress.isNotEmpty) cleanAddress,
      if (cleanUrl.isNotEmpty) cleanUrl,
    ].join('\n');

    if (message.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to share for this post yet.')),
        );
      }
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      message,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

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
    final sourceUrl = (pin['sourceUrl'] as String? ?? '').trim();
    final videoUrl =
        ((pin['videoUrl'] as String?)?.trim().isNotEmpty ?? false)
            ? (pin['videoUrl'] as String).trim()
            : sourceUrl;
    final thumbUrl = (pin['thumbnailUrl'] as String? ?? '').trim();
    final hasThumb =
        thumbUrl.isNotEmpty &&
        (thumbUrl.startsWith('http://') || thumbUrl.startsWith('https://'));

    final latValue = pin['lat'];
    final lngValue = pin['lng'];
    final lat = latValue is num ? latValue.toDouble() : null;
    final lng = lngValue is num ? lngValue.toDouble() : null;

    return CloudScaffold(
      appBar: AppBar(
        title: Text(name.isEmpty ? 'Saved import' : name),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed:
                () => _shareImport(
                  context,
                  name: name,
                  address: address,
                  sourceUrl: sourceUrl,
                ),
          ),
        ],
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
                    borderRadius: BorderRadius.circular(24),
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
                                return const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFDDEAF1),
                                        Color(0xFFBFD4E2),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFDDEAF1),
                                    Color(0xFFBFD4E2),
                                  ],
                                ),
                              ),
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.05),
                                  Colors.black.withValues(alpha: 0.28),
                                ],
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (address.isNotEmpty)
                    SoftTile(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            color: AppColors.inkDeep,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (address.isNotEmpty) const SizedBox(height: 12),
                  SoftTile(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parsed description',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          caption.isEmpty
                              ? 'No parsed description was saved for this import.'
                              : caption,
                          style: const TextStyle(
                            height: 1.4,
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (lat != null && lng != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
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
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open original Instagram link'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
