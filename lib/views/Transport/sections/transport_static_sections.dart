import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

/// Static placeholder sections matching the Transfer screen Figma, shown
/// directly below [TransportBookingCard] in place of [WhyBookTransportSection]
/// (commented out there — its content didn't match this part of the design).
/// Everything here is hardcoded UI, not wired to real data yet.

/// "Plan your multi-city road trip" banner + a page-dot indicator, matching
/// the promo card directly under the search form in the Figma.
class TransportMultiCityPromoSection extends StatelessWidget {
  const TransportMultiCityPromoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(10)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.w(14)),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(context.r(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: context.w(48),
                  height: context.w(48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.map_outlined, color: AppColors.AppBlue, size: context.w(24)),
                ),
                SizedBox(width: context.w(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Plan your multi-city road trip',
                        style: TextStyle(
                          fontSize: context.fs(14.5),
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(height: context.h(3)),
                      Text(
                        'Add stops, explore routes & create your perfect journey',
                        style: TextStyle(fontSize: context.fs(11.5), color: AppColors.subhead),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: context.w(32),
                  height: context.w(32),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.chevron_right_rounded, size: context.w(20), color: AppColors.AppBlue),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final active = i == 0;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: context.w(3)),
                width: context.w(7),
                height: context.w(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.AppBlue : const Color(0xFFD9DEE7),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// "What's New" — two static info cards.
class TransportWhatsNewSection extends StatelessWidget {
  const TransportWhatsNewSection({super.key});

  static const _cards = [
    'Make Your Trips Affordable',
    'Make Your Trips Affordable',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(20), context.w(16), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's New",
            style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600, color: AppColors.black),
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: _cards
                .map(
                  (title) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: _cards.last == title ? 0 : context.w(10)),
                      child: _whatsNewCard(context, title),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _whatsNewCard(BuildContext context, String title) {
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.w(40),
            height: context.w(40),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
            child: Icon(Icons.person_outline, color: AppColors.AppBlue, size: context.w(20)),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: AppColors.black),
                ),
                SizedBox(height: context.h(3)),
                Text(
                  'With book now Pay Later, No-Cost EMI & amazing bank offers.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(10), color: AppColors.subhead),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Offers" — horizontally scrolling static promo banners.
class TransportOffersSection extends StatelessWidget {
  const TransportOffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(24), 0, context.h(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: context.w(16)),
            child: Text(
              'Offers',
              style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600, color: AppColors.black),
            ),
          ),
          SizedBox(height: context.h(4)),
          // SizedBox(
          //   height: context.h(150),
          //   child: ListView(
          //     scrollDirection: Axis.horizontal,
          //     padding: EdgeInsets.only(right: context.w(16)),
          //     children: [
          //       _offerCard(
          //         context,
          //         gradient: const LinearGradient(colors: [Color(0xFF0B3D91), Color(0xFF1E88E5)]),
          //         title: 'More Time to Explore!',
          //         subtitle: 'Up to 20% OFF on your travel bookings this long weekend',
          //       ),
          //       SizedBox(width: context.w(12)),
          //       _offerCard(
          //         context,
          //         gradient: const LinearGradient(colors: [Color(0xFFB45309), Color(0xFFF97316)]),
          //         title: 'More Money, More Smiles',
          //         subtitle: 'Flat 10% OFF on cabs for the upcoming weekend',
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _offerCard(
    BuildContext context, {
    required Gradient gradient,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: context.w(230),
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.flight_takeoff_rounded, color: Colors.white.withValues(alpha: 0.9), size: context.w(22)),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: context.fs(15), fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: context.fs(11)),
          ),
        ],
      ),
    );
  }
}
