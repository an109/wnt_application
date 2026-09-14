import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../core/resources/app_colours.dart';
import '../views/NewSection/foryourStay.dart' show hotelData;
import 'hotel_listing_card.dart';

/// Figma "Recently Viewed" section (node 137:1117). There's no
/// recently-viewed-hotels tracking yet, so — like `RecentlyViewedSection`
/// elsewhere in the app — this reuses the same static demo entry already
/// defined for the Home screen's "For Your Stay" section instead of
/// inventing a new fake dataset.
class HotelRecentlyViewedSection extends StatelessWidget {
  const HotelRecentlyViewedSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (hotelData.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Viewed',
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: context.h(12)),
          HotelListingCard(
            hotel: hotelData.first,
            width: context.w(190),
          ),
        ],
      ),
    );
  }
}
