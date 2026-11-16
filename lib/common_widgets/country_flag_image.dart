import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a country flag image from flagcdn.com, matching the web frontend.
///
/// [isoCode] is the 2-letter ISO country code (e.g. 'in', 'ae', 'us').
/// Falls back to the emoji [fallbackFlag] when the network image fails.
class CountryFlagImage extends StatelessWidget {
  const CountryFlagImage({
    super.key,
    required this.isoCode,
    this.width = 22,
    this.height = 16,
    this.borderRadius = 2,
    this.fallbackFlag,
  });

  final String isoCode;
  final double width;
  final double height;
  final double borderRadius;
  final String? fallbackFlag;

  @override
  Widget build(BuildContext context) {
    final url = 'https://flagcdn.com/w80/${isoCode.toLowerCase()}.png';
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(width: width, height: height),
        errorWidget: (_, __, ___) => fallbackFlag != null
            ? Text(fallbackFlag!, style: TextStyle(fontSize: height))
            : Icon(Icons.flag, size: height),
      ),
    );
  }
}
