import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The Wander Nova mark, sliced into the six pieces the splash design builds
/// up one at a time: the blue stroke, the orange stroke, the teal block, then
/// WANDER, NOVA and the tagline.
///
/// Every slice shares one canvas, so they stay registered with each other no
/// matter which are on screen.
class WanderLogoLayers {
  const WanderLogoLayers._();

  static const dir = 'assets/images/splash';

  static const markBlue = '$dir/logo_mark_blue.png';
  static const markOrange = '$dir/logo_mark_orange.png';
  static const markTeal = '$dir/logo_mark_teal.png';
  static const wordWander = '$dir/logo_word_wander.png';
  static const wordNova = '$dir/logo_word_nova.png';
  static const wordTagline = '$dir/logo_word_tagline.png';

  /// "Thank you for choosing Wander Nova" strip that closes every auth screen.
  static const footerBadge = '$dir/logo_footer_badge.png';

  /// Plane, arc and badge along the bottom of the country screen.
  static const countryBottomArt = '$dir/country_bottom_art.jpg';

  /// Width / height of the shared slice canvas.
  static const aspectRatio = 876 / 750;

  static const all = <String>[
    markBlue,
    markOrange,
    markTeal,
    wordWander,
    wordNova,
    wordTagline,
  ];

  /// Decodes every slice up front so the animation's first frame is not the
  /// one that pays for the decode.
  static Future<void> precache(BuildContext context) {
    return Future.wait([
      for (final asset in all) precacheImage(AssetImage(asset), context),
    ]);
  }
}

/// Draws the mark with each slice fading and sliding into place in turn.
///
/// [progress] runs 0 → 1 across the whole build; [WanderLogo.still] renders
/// the finished logo with no animation.
class WanderLogo extends StatelessWidget {
  const WanderLogo({
    super.key,
    required this.width,
    required this.progress,
  });

  factory WanderLogo.still({Key? key, required double width}) {
    return WanderLogo(
      key: key,
      width: width,
      progress: const AlwaysStoppedAnimation<double>(1),
    );
  }

  /// Shared tag so the mark flies between the screens of the splash flow
  /// instead of being torn down and rebuilt on each one.
  static const heroTag = 'wander-nova-logo';

  final double width;
  final Animation<double> progress;

  // Each slice's slot in the timeline, plus where it travels in from
  // (as a fraction of the logo width) and the scale it grows out of. The
  // windows overlap generously so the pieces cascade instead of stepping.
  static const _steps = <_LogoStep>[
    _LogoStep(WanderLogoLayers.markBlue, 0.00, 0.30, Offset(-0.05, 0.08), 0.90),
    _LogoStep(WanderLogoLayers.markOrange, 0.14, 0.46, Offset(0.06, 0.08), 0.90),
    _LogoStep(WanderLogoLayers.markTeal, 0.32, 0.60, Offset(0.04, -0.08), 0.90),
    _LogoStep(WanderLogoLayers.wordWander, 0.48, 0.74, Offset(-0.02, 0.05), 0.95),
    _LogoStep(WanderLogoLayers.wordNova, 0.62, 0.86, Offset(0.02, 0.05), 0.95),
    _LogoStep(WanderLogoLayers.wordTagline, 0.76, 1.00, Offset(0, 0.04), 0.97),
  ];

  @override
  Widget build(BuildContext context) {
    // A slow, even swell across the whole build keeps the piece-by-piece
    // entrances from reading as separate events.
    final settle = CurvedAnimation(parent: progress, curve: Curves.easeOutSine);

    return SizedBox(
      width: width,
      height: width / WanderLogoLayers.aspectRatio,
      child: AnimatedBuilder(
        animation: settle,
        builder: (context, child) => Transform.scale(
          scale: lerpDouble(0.95, 1.0, settle.value)!,
          child: child,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [for (final step in _steps) _buildStep(step)],
        ),
      ),
    );
  }

  Widget _buildStep(_LogoStep step) {
    // Quartic ease-out for the travel: fast on entry, a long glide to rest.
    final motion = CurvedAnimation(
      parent: progress,
      curve: Interval(step.begin, step.end, curve: Curves.easeOutQuart),
    );
    // Opacity lands a little before the movement does, so nothing arrives
    // while still visibly fading.
    final fade = CurvedAnimation(
      parent: progress,
      curve: Interval(
        step.begin,
        step.begin + (step.end - step.begin) * 0.72,
        curve: Curves.easeOut,
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([motion, fade]),
      builder: (context, child) {
        final t = motion.value;
        final rest = 1 - t;
        return Opacity(
          opacity: fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              step.from.dx * width * rest,
              step.from.dy * width * rest,
            ),
            child: Transform.scale(
              scale: lerpDouble(step.fromScale, 1.0, t)!,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        step.asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _LogoStep {
  const _LogoStep(this.asset, this.begin, this.end, this.from, this.fromScale);

  final String asset;
  final double begin;
  final double end;
  final Offset from;
  final double fromScale;
}
