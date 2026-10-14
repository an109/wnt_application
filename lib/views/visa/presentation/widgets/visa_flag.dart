import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/visa_countries.dart';

/// Circular country flag, as the round emojione flags in the designs.
class VisaFlag extends StatelessWidget {
  final String? countryCode;
  final double size;

  const VisaFlag({super.key, required this.countryCode, required this.size});

  @override
  Widget build(BuildContext context) {
    final code = countryCode?.toLowerCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
      child: Icon(Icons.public, size: size * 0.6, color: Colors.white),
    );
    if (code == null) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: 'https://flagcdn.com/w160/$code.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              VisaCountry('', code.toUpperCase()).emoji,
              style: TextStyle(fontSize: size * 0.6),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
