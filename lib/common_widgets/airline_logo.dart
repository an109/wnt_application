import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Airline logo fetched from the Kiwi CDN by IATA code, with a graceful
/// fallback to a coloured initials tile when the code/logo is missing or
/// fails to load. Mirrors the pattern already used for AkFlightInfo cards
/// (detail_popup.dart's `_airlineBadge`), extracted here so it can be
/// reused wherever an airline needs to be shown by code/name.
class AirlineLogo extends StatelessWidget {
  final String code;
  final String name;
  final double size;
  final BorderRadius? borderRadius;

  const AirlineLogo({
    super.key,
    required this.code,
    required this.name,
    required this.size,
    this.borderRadius,
  });

  static String _initials(String code, String name) {
    final source = code.trim().isNotEmpty ? code : name;
    final letters = source.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (letters.length >= 2) return letters.substring(0, 2);
    return letters.isEmpty ? 'FL' : letters;
  }

  static Color _colorFor(String initials) {
    const colors = [
      Color(0xffC29200),
      Color(0xff25358D),
      Color(0xff7A003C),
      Color(0xff0F766E),
      Color(0xffB42318),
    ];
    final hash = initials.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final logoCode = code.trim().toUpperCase();
    final initials = _initials(logoCode, name);
    final radius = borderRadius ?? BorderRadius.circular(size * 0.18);

    Widget initialsTile() => Container(
          color: _colorFor(initials),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.28,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xffE6ECFF)),
      ),
      child: logoCode.isEmpty
          ? initialsTile()
          : Padding(
              padding: EdgeInsets.all(size * 0.06),
              child: CachedNetworkImage(
                imageUrl: 'https://images.kiwi.com/airlines/64/$logoCode.png',
                fit: BoxFit.contain,
                placeholder: (_, __) => initialsTile(),
                errorWidget: (_, __, ___) => initialsTile(),
              ),
            ),
    );
  }
}
