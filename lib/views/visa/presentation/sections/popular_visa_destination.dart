import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../widget/destinaiton_card.dart';


class PopularVisaDestinations extends StatelessWidget {
  const PopularVisaDestinations({super.key});

  @override
  Widget build(BuildContext context) {

    final destinations = [

      {
        "image":
        "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1200&auto=format&fit=crop",
        "country": "United Arab Emirates",
        "type": "Middle East",
        "price": "8,619",
        "processing": "48-96 hours",
      },

      {
        "image":
        "https://images.unsplash.com/photo-1485738422979-f5c462d49f74?q=80&w=1200&auto=format&fit=crop",
        "country": "United States",
        "type": "North America",
        "price": "33,520",
        "processing": "7-10 Days",
      },

      {
        "image":
        "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?q=80&w=1200&auto=format&fit=crop",
        "country": "United Kingdom",
        "type": "Europe",
        "price": "38,309",
        "processing": "3 Weeks",
      },

      {
        "image":
        "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?q=80&w=1200&auto=format&fit=crop",
        "country": "Germany",
        "type": "Schengen",
        "price": "19,154",
        "processing": "15 Days",
      },
    ];

    return Padding(
      padding: context.horizontalPadding,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Popular Destinations",
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: context.gapLarge),

          SizedBox(
            height: context.isMobile ? 310 : 360,

            child: ListView.separated(
              scrollDirection: Axis.horizontal,

              physics: context.scrollPhysics,

              itemCount: destinations.length,

              separatorBuilder: (_, __) =>
                  SizedBox(width: context.gapMedium),

              itemBuilder: (context, index) {

                final item = destinations[index];

                return DestinationCard(
                  image: item["image"]!,
                  country: item["country"]!,
                  type: item["type"]!,
                  price: item["price"]!,
                  processing: item["processing"]!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}