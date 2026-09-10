import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PinCard extends StatelessWidget {
  final String name;
  final String address;
  final String thumbUrl;
  final double? lat;
  final double? lng;
  final double imageHeight;
  final VoidCallback? onTap;
  final Widget? overlay;
  final int gradientIndex;
  final bool isPromoted;

  const PinCard({
    super.key,
    required this.name,
    required this.address,
    this.thumbUrl = '',
    this.lat,
    this.lng,
    this.imageHeight = 140,
    this.onTap,
    this.overlay,
    this.gradientIndex = 0,
    this.isPromoted = false,
  });

  bool get _hasThumb {
    final url = thumbUrl.trim();
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final fallback =
        AppColors.pinFallbackGradients[gradientIndex %
            AppColors.pinFallbackGradients.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cloud.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.hairline),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_hasThumb)
                        Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return DecoratedBox(
                              decoration: BoxDecoration(gradient: fallback),
                            );
                          },
                        )
                      else
                        DecoratedBox(
                          decoration: BoxDecoration(gradient: fallback),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.02),
                              Colors.black.withValues(alpha: 0.22),
                            ],
                          ),
                        ),
                      ),
                      if (isPromoted)
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: _OutboundAdMark(),
                          ),
                        )
                      else
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      if (overlay != null) overlay!,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (!isPromoted && lat != null && lng != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: AppColors.ink.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lat!.toStringAsFixed(2)}, ${lng!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutboundAdMark extends StatelessWidget {
  const _OutboundAdMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.north_east_rounded,
        size: 14,
        color: AppColors.inkDeep,
      ),
    );
  }
}
