import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

/// Colours, type and assets of the Trisha AI screens ("AI 1/2/3" Figma frames).
class TrishaStyle {
  TrishaStyle._();

  static const brandBlue = Color(0xFF3D8BE8);
  static const brandBlueLight = Color(0xFF6BB8F5);
  static const userBubble = Color(0xFF479FE1);
  static const accent = AppColors.orange;
  static const text = Color(0xFF1A1A1A);
  static const hint = Color(0xFF8A8F98);
  static const cardBorder = Color(0xFFE6EBF2);
  static const listBg = Color(0xFFF7F9FD);
  static const quickReplyBg = Color(0xFFEEF7FE);
  static const quickReplyDivider = Color(0xFFDCEAF7);

  // Exported from the Figma file (frame "AI 1"). Until a file is added, the
  // widgets below fall back to a plain placeholder rather than crashing.
  static const orbAsset = 'assets/trisha/trisha_orb.png'; // "FULL ai"
  static const cardFlightAsset = 'assets/trisha/card_flight.png';
  static const cardStayAsset = 'assets/trisha/card_stay.png';
  static const cardHolidayAsset = 'assets/trisha/card_holiday.png';
  static const micAsset = 'assets/trisha/mic_ai.svg'; // mingcute:mic-ai-fill

  /// Display serif used for "Thrisha.AI", "Hi, NAME" and the "Thrisha" label.
  static TextStyle display(BuildContext context, double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.gelasio(fontSize: context.ffs(size), fontWeight: weight, color: brandBlue);

  static TextStyle body(BuildContext context, double size,
          {Color color = text, FontWeight weight = FontWeight.w400, double height = 1.45}) =>
      TextStyle(fontSize: context.ffs(size), color: color, fontWeight: weight, height: height);

  static List<BoxShadow> get softShadow => const [
        BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
      ];
}

/// The Trisha orb. [glow] adds the soft blue halo used on the welcome screen
/// and behind the bottom-nav button.
class TrishaOrb extends StatelessWidget {
  final double size;
  final bool glow;

  const TrishaOrb({super.key, required this.size, this.glow = false});

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [BoxShadow(color: const Color(0x334A9FE8), blurRadius: size * 0.25)],
      ),
      child: ClipOval(
        child: Image.asset(
          TrishaStyle.orbAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _OrbPlaceholder(),
        ),
      ),
    );
    if (!glow) return orb;
    return Container(
      width: size * 2.2,
      height: size * 2.2,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x553D9BE9), Color(0x1A3D9BE9), Color(0x003D9BE9)],
          stops: [0.3, 0.65, 1],
        ),
      ),
      child: orb,
    );
  }
}

/// Shown only until trisha_orb.png is exported from Figma.
class _OrbPlaceholder extends StatelessWidget {
  const _OrbPlaceholder();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFFFFF3C4), Color(0xFFF97316), Color(0xFF2F6FE0), Colors.white],
            stops: [0.0, 0.25, 0.6, 1.0],
          ),
        ),
      );
}

/// Asset image with an icon fallback until the Figma export is added.
class TrishaAssetImage extends StatelessWidget {
  final String asset;
  final double size;
  final IconData fallback;

  const TrishaAssetImage({super.key, required this.asset, required this.size, required this.fallback});

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(fallback, size: size, color: TrishaStyle.brandBlue),
      );
}

class TrishaMicIcon extends StatelessWidget {
  final double size;

  const TrishaMicIcon({super.key, required this.size});

  // flutter_svg reports a missing asset as an unhandled error instead of using
  // errorBuilder, so check the bundle once before asking for the SVG.
  static final Future<bool> _exported = AssetManifest.loadFromAssetBundle(rootBundle)
      .then((m) => m.listAssets().contains(TrishaStyle.micAsset))
      .catchError((_) => false);

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.mic_rounded, size: size, color: TrishaStyle.brandBlue);
    return FutureBuilder<bool>(
      future: _exported,
      builder: (context, snap) => snap.data == true
          ? SvgPicture.asset(TrishaStyle.micAsset, width: size, height: size)
          : fallback,
    );
  }
}

/// White 32×32 round button of the top bar (close / menu).
class TrishaCircleButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback? onTap;

  const TrishaCircleButton({super.key, required this.icon, required this.iconSize, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: context.fx(32),
          height: context.fx(32),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: TrishaStyle.softShadow,
          ),
          child: Icon(icon, size: iconSize, color: TrishaStyle.text),
        ),
      );
}
