import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../widget/holiday_search_card.dart';


class HolidaysBannerSection extends StatelessWidget {
  const HolidaysBannerSection({super.key});

  @override
  Widget build(BuildContext context) {

    return Stack(
      clipBehavior: Clip.none,
      children: [

        /// BACKGROUND IMAGE
        SizedBox(
          height: context.isMobile
              ? context.hp(42)
              : context.hp(58),

          width: double.infinity,

          child: Stack(
            fit: StackFit.expand,
            children: [

              Image.network(
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1600&auto=format&fit=crop",
                fit: BoxFit.cover,
              ),

              Container(
                color: Colors.black.withOpacity(0.12),
              ),
            ],
          ),
        ),

        /// SEARCH CARD
        Positioned(
          left: context.isMobile
              ? context.wp(4)
              : context.wp(8),

          right: context.isMobile
              ? context.wp(4)
              : context.wp(8),

          top: context.isMobile
              ? context.hp(3)
              : context.hp(5),

          child: const HolidaysSearchCard(),
        ),
      ],
    );
  }
}