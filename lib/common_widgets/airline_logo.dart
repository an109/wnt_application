import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Airline logo. The sharp 128px logo kept on our own site (the same files the
/// website uses, thewandernova.com/airlines/<code>.png) is used when there is
/// one; otherwise the 30px picture from the TBO CloudFront CDN, then
/// pics.avs.io, and a coloured initials tile as the last resort.
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
  static const _ownBase = 'https://thewandernova.com/airlines';

  // Airlines whose sharp logo is on our site (public/airlines on the website).
  static const _ownLogoCodes = {
    '2T', '3K', '3U', '5J', '6E', '7C', '8M', '9I', '9W', 'A3',
    'AA', 'AC', 'AF', 'AI', 'AK', 'AM', 'AS', 'AT', 'AV', 'AY',
    'AZ', 'B6', 'BA', 'BG', 'BR', 'BS', 'BT', 'CA', 'CI', 'CM',
    'CX', 'CZ', 'D7', 'DL', 'DN', 'DY', 'EI', 'EK', 'ET', 'EW',
    'EY', 'F9', 'FD', 'FI', 'FJ', 'FR', 'FZ', 'G8', 'G9', 'GA',
    'GF', 'HU', 'HV', 'HX', 'I5', 'IB', 'ID', 'IT', 'IX', 'J9',
    'JL', 'JP', 'JQ', 'JT', 'JU', 'KA', 'KB', 'KE', 'KL', 'KM',
    'KQ', 'KU', 'LA', 'LH', 'LJ', 'LO', 'LX', 'LY', 'ME', 'MF',
    'MH', 'MS', 'MU', 'NH', 'NK', 'NX', 'NZ', 'OD', 'OG', 'OK',
    'OS', 'OZ', 'PC', 'PG', 'PR', 'QF', 'QG', 'QH', 'QP', 'QR',
    'RJ', 'RO', 'S5', 'SA', 'SC', 'SG', 'SK', 'SN', 'SQ', 'SU',
    'SV', 'TG', 'TK', 'TO', 'TP', 'TR', 'TU', 'TW', 'U2', 'UA',
    'UB', 'UK', 'UL', 'VA', 'VJ', 'VN', 'VS', 'VY', 'W6', 'WB',
    'WN', 'WY', 'XY', 'ZH',
  };

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
    if (_ownLogoCodes.contains(code)) return '$_ownBase/$code.png';
    return '$_cloudFrontBase/$code.jpg?V2';
  }

  static String fallbackLogoUrl(String airlineCode) {
    final code = _resolveCode(airlineCode);
    // Our own logo failed to load: the smaller CloudFront one is next. For an
    // airline we hold no logo for, CloudFront was already tried, so pics.avs.io.
    if (_ownLogoCodes.contains(code)) return '$_cloudFrontBase/$code.jpg?V2';
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
                  imageUrl: fallbackLogoUrl(logoCode),
                  fit: BoxFit.contain,
                  placeholder: (_, __) => initialsTile(),
                  errorWidget: (_, __, ___) => initialsTile(),
                ),
              ),
            ),
    );
  }
}
