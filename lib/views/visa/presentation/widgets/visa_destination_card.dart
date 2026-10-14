import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../Visa_popularDestinaton/domain/entities/visa_destination_entity.dart';
import '../utils/visa_rules.dart';
import '../utils/visa_theme.dart';
import 'visa_flag.dart';

/// Destination tile of the Visa home grid (Figma "Card 1: Thailand").
class VisaDestinationCard extends StatelessWidget {
  final VisaPopularDestinationEntity destination;
  final VoidCallback onTap;

  const VisaDestinationCard({super.key, required this.destination, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = destination.primaryType;
    final processing = type?.parsedProcessing ?? destination.fastestProcessing;
    final guaranteed = processing?.guaranteedFrom(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1),
                  BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _image(destination.cardImage),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xCC000000), Color(0x4D000000), Color(0x00000000)],
                        stops: [0, 0.5, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 8),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: VisaColors.divider, width: 0.2)),
                            ),
                            child: Column(
                              children: [
                                VisaFlag(countryCode: destination.countryCode, size: 34),
                                Text(
                                  destination.shortName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: visaText(12,
                                      weight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 20 / 12,
                                      letterSpacing: 0.35),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _stat('TYPE', type == null ? '—' : destination.kindOf(type).badge)),
                              Expanded(
                                child: _stat(
                                  'VALID',
                                  (type?.validity ?? '').isEmpty ? '—' : type!.validity.toUpperCase(),
                                  end: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guaranteed Visa On',
                  style: visaText(12, weight: FontWeight.w600, height: 16.5 / 12),
                ),
                const SizedBox(height: 2),
                Text(
                  guaranteed == null ? 'On request' : visaDateTimeFormat.format(guaranteed),
                  style: visaText(8, color: VisaColors.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {bool end = false}) {
    final align = end ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: visaText(8, color: Colors.white, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: end ? TextAlign.right : TextAlign.left,
          style: visaText(10, weight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }

  Widget _image(String url) {
    if (url.isEmpty) return Container(color: const Color(0xFFCBD5E1));
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: const Color(0xFFE2E8F0)),
      errorWidget: (_, __, ___) => Container(color: const Color(0xFFCBD5E1)),
    );
  }
}
