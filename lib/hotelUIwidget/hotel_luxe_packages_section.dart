import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../views/NewSection/foryourStay.dart' show hotelData;
import 'hotel_listing_card.dart';
import 'hotel_section_heading.dart';

/// Figma "Luxe - Best Packages" section (node 137:1117). Same reuse
/// rationale as [HotelRecentlyViewedSection] — no best-packages API yet, so
/// this reuses the existing `hotelData` demo list rather than a new one.
class HotelLuxePackagesSection extends StatelessWidget {
  const HotelLuxePackagesSection({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (hotelData.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HotelSectionHeading(
            title: 'Luxe - Best Packages',
            subtitle: 'Explore your best hotel according to you',
            onViewAll: onViewAll,
          ),
          SizedBox(height: context.h(14)),
          SizedBox(
            // A bit more than the card's natural content height for slack
            // against larger system text-scale settings (not clamped
            // app-wide) — avoids a RenderFlex overflow on real devices.
            height: context.h(268),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hotelData.length,
              separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
              itemBuilder: (_, index) => HotelListingCard(
                hotel: hotelData[index],
                width: context.w(170),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
