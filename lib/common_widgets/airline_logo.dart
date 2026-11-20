import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Airline logo fetched from the CloudFront CDN (same source as the web
/// frontend), with pics.avs.io as fallback, and coloured initials tile as
/// the last resort.
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

  static const _cloudFrontBase =
      'https://dhiz4uvf5rpaq.cloudfront.net/images/airline-logos';

  // Fare-channel variants that map to a base IATA code, matching the web
  // frontend's airlineLogos overrides.
  static const _codeAliases = {
    'QP': 'QP', 'CQP': 'QP', 'EQP': 'QP', 'SQP': 'QP',
    'JCL': 'QP', 'NT': 'QP',
    'CSG': 'SG', 'ESG': 'SG',
  };

  static String _resolveCode(String raw) {
    final code = raw.trim().toUpperCase().replaceAll(RegExp(r'\s'), '');
    return _codeAliases[code] ?? code;
  }

  static String getLogoUrl(String airlineCode) {
    final code = _resolveCode(airlineCode);
    if (code.isEmpty) return '';
    return '$_cloudFrontBase/$code.jpg?V2';
  }

  static String _fallbackUrl(String airlineCode) {
    final code = _resolveCode(airlineCode);
    return 'https://pics.avs.io/120/120/$code.png';
  }

  static String _initials(String code, String name) {
    final source = code.trim().isNotEmpty ? code : name;
    final letters =
        source.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
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
    final logoCode = _resolveCode(code);
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
                imageUrl: getLogoUrl(logoCode),
                fit: BoxFit.contain,
                placeholder: (_, __) => initialsTile(),
                errorWidget: (_, __, ___) => CachedNetworkImage(
                  imageUrl: _fallbackUrl(logoCode),
                  fit: BoxFit.contain,
                  placeholder: (_, __) => initialsTile(),
                  errorWidget: (_, __, ___) => initialsTile(),
                ),
              ),
            ),
    );
  }
}
