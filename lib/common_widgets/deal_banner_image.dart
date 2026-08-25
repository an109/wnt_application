import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'fast_network_image_cache_manager.dart';

/// The full-bleed photo behind an exclusive-deal banner card.
///
/// Replaces the plain `DecorationImage(NetworkImage(...))` these cards used
/// to paint with. `NetworkImage` keeps nothing on disk, so every launch
/// re-downloaded the same banners, and it decodes at the source photo's
/// native resolution — banners are wide marketing images, so that was
/// routinely several times more pixels than the card can show. This variant
/// caches to disk (shared with the rest of the app's remote images), bounds
/// each fetch with a timeout, and decodes no wider than the screen.
///
/// Layout is deliberately unchanged: it fills its parent exactly the way
/// `BoxFit.cover` did.
///
/// The fallback for a missing/failed image is a flat neutral fill rather than
/// the `assets/images/placeholder_deal.png` the old `DecorationImage` named —
/// that asset isn't in the bundle, so the old code silently swallowed the
/// load error and painted nothing. A flat fill matches the loading state of
/// the carousel around it instead of leaving a hole.
class DealBannerImage extends StatelessWidget {
  final String imageUrl;

  const DealBannerImage({super.key, required this.imageUrl});

  /// Decoded-bitmap width for a banner. Cards are full-width, so the screen's
  /// physical pixel width is the most any of them can display.
  static int _decodeWidth(BuildContext context) {
    final logicalWidth = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalWidth * dpr).round().clamp(320, 2160);
  }

  static ImageProvider _providerFor(BuildContext context, String url) {
    return ResizeImage.resizeIfNeeded(
      _decodeWidth(context),
      null,
      CachedNetworkImageProvider(
        url,
        cacheManager: FastNetworkImageCacheManager.instance,
      ),
    );
  }

  /// Starts downloading and decoding [urls] in the background so slides the
  /// carousel hasn't reached yet are already cached when it gets there.
  /// Every failure is swallowed — a banner that can't be pre-fetched simply
  /// falls back to loading normally when its slide comes up.
  static void prefetch(BuildContext context, Iterable<String> urls) {
    for (final url in urls) {
      if (url.trim().isEmpty) continue;
      try {
        precacheImage(
          _providerFor(context, url.trim()),
          context,
          onError: (_, __) {},
        );
      } catch (_) {
        // Pre-fetching is a pure optimisation.
      }
    }
  }

  Widget _fallback() => Container(color: Colors.grey.shade200);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) return _fallback();

    return CachedNetworkImage(
      imageUrl: imageUrl.trim(),
      cacheManager: FastNetworkImageCacheManager.instance,
      fit: BoxFit.cover,
      memCacheWidth: _decodeWidth(context),
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }
}
