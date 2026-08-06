import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class WhyChooseUs extends StatelessWidget {
  const WhyChooseUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(24)),
      child: Column(
        children: [
          Text(
            "Why Choose Wander Nova?",
            style: TextStyle(
              fontSize: context.headlineSmall,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: context.gapMedium),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(24)), // 24px on design
            child: Text(
              "Your trusted partner for flights, hotels, holidays & visa — with great prices and support every step of the way.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey[600],
              ),
            ),
          ),

          SizedBox(height: context.h(24)),

          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = context.gridCrossAxisCount;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: context.gapMedium,
                mainAxisSpacing: context.gapMedium,
                padding: context.horizontalPadding,
                childAspectRatio: context.gridChildAspectRatio,
                children: const [
                  _Item(
                    icon: Icons.flight_takeoff,
                    title: "EASY BOOKING",
                    desc:
                    "Search, compare and book flights, hotels and packages in minutes with a simple, secure checkout.",
                  ),
                  _Item(
                    icon: Icons.attach_money,
                    title: "BEST PRICE GUARANTEE",
                    desc:
                    "Competitive rates, exclusive deals and weekly offers so you always get the best value.",
                  ),
                  _Item(
                    icon: Icons.apartment,
                    title: "WIDE REACH",
                    desc:
                    "Access to a global network of airlines, hotels and destinations for domestic and international travel.",
                  ),
                  _Item(
                    icon: Icons.headset_mic,
                    title: "24/7 SUPPORT",
                    desc:
                    "Round-the-clock assistance for bookings, changes and queries — we're here whenever you need us.",
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _Item({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(16)), // 16px on design
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.h(12),
            offset: Offset(0, context.h(4)),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.w(14)), // 14px on design
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.red,
              size: context.iconMedium,
            ),
          ),

          SizedBox(height: context.gapMedium),

          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.labelLarge,
              fontWeight: FontWeight.bold,
              letterSpacing: context.letterSpacingNormal,
            ),
          ),

          SizedBox(height: context.gapMedium),

          Flexible(
            child: Text(
              desc,
              textAlign: TextAlign.center,
              maxLines: context.isMobile ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey[600],
                height: context.isMobile ? 1.4 : (context.isTablet ? 1.5 : 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}