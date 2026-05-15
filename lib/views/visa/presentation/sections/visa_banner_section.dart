import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../widget/visa_search_card.dart';


class VisaBannerSection extends StatelessWidget {
  const VisaBannerSection({super.key});

  @override
  Widget build(BuildContext context) {

    return Stack(
      clipBehavior: Clip.none,
      children: [

        /// BANNER IMAGE
        SizedBox(
          height: context.isMobile
              ? context.hp(38)
              : context.hp(50),

          width: double.infinity,

          child: Stack(
            fit: StackFit.expand,
            children: [

              Image.network(
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1400&auto=format&fit=crop",
                fit: BoxFit.cover,
              ),

              Container(
                color: Colors.black.withOpacity(0.25),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(6),
                  vertical: context.hp(5),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(height: context.hp(9)),

                    Text(
                      "Choose Destination.",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: context.sp(28),
                        height: 1.2,
                      ),
                    ),

                    SizedBox(height: context.hp(0.2)),

                    Text(
                      "We'll Handle the Visa",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// SEARCH CARD
        Positioned(
          left: context.wp(4),
          right: context.wp(4),
          bottom: -context.hp(-7),

          child: const VisaSearchCard(),
        ),
      ],
    );
  }
}