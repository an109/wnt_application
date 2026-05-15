import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package_card.dart';

class TrendingPackages extends StatelessWidget {
  const TrendingPackages({super.key});

  final List<Map<String, dynamic>> routes = const [
    {
      "from": "Mumbai",
      "to": "Bangalore",
      "fromCode": "BOM",
      "toCode": "BLR",
      "date": "06/05/2026",
      "price": "5,087",
      "image": "https://picsum.photos/200/200?1"
    },
    {
      "from": "Kerala",
      "to": "Singapore",
      "fromCode": "COK",
      "toCode": "SIN",
      "date": "06/05/2026",
      "price": "31,092",
      "image": "https://picsum.photos/200/200?2"
    },
    {
      "from": "Mumbai",
      "to": "Chennai",
      "fromCode": "BOM",
      "toCode": "MAA",
      "date": "06/05/2026",
      "price": "6,852",
      "image": "https://picsum.photos/200/200?3"
    },
    {
      "from": "Mumbai",
      "to": "Dubai",
      "fromCode": "BOM",
      "toCode": "DXB",
      "date": "06/05/2026",
      "price": "39,604",
      "image": "https://picsum.photos/200/200?4"
    },
    {
      "from": "Mumbai",
      "to": "New Delhi",
      "fromCode": "BOM",
      "toCode": "DEL",
      "date": "06/05/2026",
      "price": "6,955",
      "image": "https://picsum.photos/200/200?5"
    },
    {
      "from": "Mumbai",
      "to": "Muscat",
      "fromCode": "BOM",
      "toCode": "MCT",
      "date": "06/05/2026",
      "price": "21,930",
      "image": "https://picsum.photos/200/200?6"
    },
    {
      "from": "Kochi",
      "to": "Abu Dhabi",
      "fromCode": "COK",
      "toCode": "AUH",
      "date": "06/05/2026",
      "price": "36,490",
      "image": "https://picsum.photos/200/200?7"
    },
    {
      "from": "Kolkata",
      "to": "Mumbai",
      "fromCode": "CCU",
      "toCode": "BOM",
      "date": "06/05/2026",
      "price": "10,926",
      "image": "https://picsum.photos/200/200?8"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(1.5)),
          child: Text(
            "Trending Routes With Best Prices",
            style: TextStyle(
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(
          height: context.hp(24),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.wp(3)),
            itemCount: (routes.length / 2).ceil(),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  RouteCard(route: routes[index * 2]),
                  SizedBox(height: context.gapMedium),
                  if (index * 2 + 1 < routes.length)
                    RouteCard(route: routes[index * 2 + 1]),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}