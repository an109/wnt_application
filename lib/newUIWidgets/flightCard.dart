import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

/// Result card for a single flight option — matches the Wander Nova Figma
/// ("Search Flight own way"): navy logo tile + airline name, cyan
/// "₹ … /adult" price on one line, a hairline divider, then
/// departure / orange arc with a blue plane / arrival.
///
/// Fully responsive — every size goes through the `context.w/h/r/fs`
/// helpers — and it inherits the app's Manrope text theme (no `fontFamily`
/// override anywhere).
class FlightCard extends StatelessWidget {
  final String airlineName;
  final String flightNumber;

  /// Widget shown inside the navy logo tile (e.g. a network airline logo or
  /// a fallback icon). Sized/clipped by the tile itself.
  final Widget logo;

  /// Fully formatted price, currency symbol included — e.g. "₹ 35,442".
  final String priceText;

  /// Small grey suffix drawn inline after the price.
  final String perLabel;

  final String departureCity;
  final String departureCode;
  final String departureTime;

  final String arrivalCity;
  final String arrivalCode;
  final String arrivalTime;

  /// Human duration, e.g. "3h 40m".
  final String duration;

  /// "Non stop" / "1 Stop" / "" (hidden when empty).
  final String stopsLabel;

  /// Optional extra content rendered inside the card, below the route row
  /// (e.g. an offer strip or a "N more flights" toggle).
  final Widget? footer;

  const FlightCard({
    super.key,
    required this.airlineName,
    required this.flightNumber,
    required this.logo,
    required this.priceText,
    required this.departureCity,
    required this.departureCode,
    required this.departureTime,
    required this.arrivalCity,
    required this.arrivalCode,
    required this.arrivalTime,
    required this.duration,
    this.stopsLabel = 'Non stop',
    this.perLabel = '/adult',
    this.footer,
  });

  static const Color _navy = Color(0xFF1E1E5A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(18),
        vertical: context.h(18),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(18)),
        border: Border.all(color: const Color(0xFFEDEEF1), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1E5A).withValues(alpha: 0.05),
            blurRadius: context.w(18),
            offset: Offset(0, context.h(6)),
          ),
        ],
      ),
      child: Column(
        children: [
          _headerRow(context),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(12)),
            child: Container(height: 0.6, color: const Color(0xFFCCCCCC)),
          ),
          _routeRow(context),
          if (footer != null) footer!,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- HEADER

  Widget _headerRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: context.w(38),
          height: context.w(38),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: logo,
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  airlineName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              SizedBox(width: context.w(4)),
              Flexible(
                child: Text(
                  flightNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.subhead,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Price remains the same
        SizedBox(width: context.w(8)),
        Text.rich(
          TextSpan(
            text: priceText,
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: AppColors.AppBlue,
            ),
            children: [
              TextSpan(
                text: ' $perLabel',
                style: TextStyle(
                  fontSize: context.fs(8),
                  fontWeight: FontWeight.w700,
                  color: AppColors.subhead,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- ROUTE

  Widget _routeRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _endpoint(
            context,
            city: departureCity,
            time: departureTime,
            code: departureCode,
            alignEnd: false,
          ),
        ),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Replaced CustomPaint with Image.asset
              SizedBox(
                height: context.h(46.2),
                width: double.infinity,
                child: Image.asset(
                  'assets/NewIcons/flightCard.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
              // SizedBox(height: context.h(1)),
              Text(
                duration,
                style: TextStyle(fontSize: context.fs(10), color: AppColors.subhead),
              ),
              if (stopsLabel.isNotEmpty) ...[
                SizedBox(height: context.h(1)),
                Text(
                  stopsLabel,
                  style: TextStyle(fontSize: context.fs(10), color: AppColors.subhead),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: _endpoint(
            context,
            city: arrivalCity,
            time: arrivalTime,
            code: arrivalCode,
            alignEnd: true,
          ),
        ),
      ],
    );
  }

  Widget _endpoint(
      BuildContext context, {
        required String city,
        required String time,
        required String code,
        required bool alignEnd,
      }) {
    final align =
    alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          city,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: context.fs(12),
            color: AppColors.subhead,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.h(4)),
        Text(
          time,
          maxLines: 1,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: context.fs(20),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: context.h(4)),
        Text(
          code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(fontSize: context.fs(12), color: AppColors.subhead),
        ),
      ],
    );
  }
}
