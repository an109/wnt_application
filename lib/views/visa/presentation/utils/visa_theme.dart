import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens of the Visa section (Figma "Wander Nova App – Visa").
class VisaColors {
  VisaColors._();

  static const primary = Color(0xFF00A1E4);
  static const primaryLight = Color(0xFF80DAFF);
  static const primarySoft = Color(0xFFE6F6FD);
  static const title = Color(0xFF111527);
  static const text = Color(0xFF757575);
  static const stroke = Color(0xFFCCCCCC);
  static const divider = Color(0xFFF2F2F7);
  static const cta = Color(0xFFF07A2D);
  static const teal = Color(0xFF0B9D9D);
  static const green = Color(0xFF22C55E);
  static const greenSoft = Color(0xFFEFFBF3);
  static const red = Color(0xFFFF383C);
  static const surface = Color(0xFFF7F8FA);
}

/// Manrope text style at the exact Figma size.
TextStyle visaText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = Colors.black,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
}) {
  return GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: color,
  );
}

/// Section caption such as "PASSPORT INFORMATION".
class VisaSectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const VisaSectionLabel({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor = VisaColors.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: visaText(11, weight: FontWeight.w700, color: VisaColors.title),
        ),
      ],
    );
  }
}

/// Full-width orange call to action used at the bottom of the visa screens.
class VisaPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const VisaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: VisaColors.cta,
          disabledBackgroundColor: VisaColors.cta.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label.toUpperCase(),
                style: visaText(12, weight: FontWeight.w700, color: Colors.white),
              ),
      ),
    );
  }
}

/// White sheet surface with the grey drag handle and a floating close button
/// above it, as used by every picker in the Visa designs.
class VisaSheet extends StatelessWidget {
  final Widget child;
  final bool showHandle;

  const VisaSheet({super.key, required this.child, this.showHandle = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 18, color: VisaColors.title),
            ),
          ),
        ),
        Flexible(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHandle)
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VisaColors.stroke,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<T?> showVisaSheet<T>(BuildContext context, Widget child, {bool showHandle = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: VisaSheet(showHandle: showHandle, child: child),
    ),
  );
}
