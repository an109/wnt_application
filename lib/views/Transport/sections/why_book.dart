import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class WhyBookTransportSection extends StatelessWidget {
  const WhyBookTransportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F6F7),

      padding: EdgeInsets.symmetric(
        horizontal: context.wp(5),
        vertical: context.hp(2),
      ),

      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.isDesktop
                ? 700
                : context.isTablet
                ? 560
                : double.infinity,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.hp(2)),

              /// TITLE
              Text(
                "Why Book Ground\nTransport with Us?",
                style: TextStyle(
                  fontSize: context.sp(22),
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: const Color(0xFF102347),
                ),
              ),

              SizedBox(height: context.hp(1.4)),

              /// BLUE LINE
              Container(
                width: context.wp(7),
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              SizedBox(height: context.hp(2.2)),

              /// DESCRIPTION
              Text(
                "Reliable transfers worldwide — airport pickups,\ncity transfers, intercity rides and more.",
                style: TextStyle(
                  fontSize: context.sp(13.5),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),

              SizedBox(height: context.hp(4)),

              /// PRIVATE TRANSFERS
              const TransportCard(
                icon: Icons.directions_car_rounded,
                iconBg: Color(0xFFEAF1FF),
                iconColor: Color(0xFF2F80ED),
                title: "Private Transfers",
                description:
                "Exclusive vehicle just for you —\nno shared rides, no waiting.",
              ),

              SizedBox(height: context.hp(2.5)),

              /// SHARED SHUTTLES
              const TransportCard(
                icon: Icons.airport_shuttle_rounded,
                iconBg: Color(0xFFE8F7EE),
                iconColor: Color(0xFF27AE60),
                title: "Shared Shuttles",
                description:
                "Budget-friendly shared rides\nwith fixed pickup times.",
              ),

              SizedBox(height: context.hp(2.5)),

              /// MEET & GREET
              const TransportCard(
                icon: Icons.location_on_outlined,
                iconBg: Color(0xFFFCEEE9),
                iconColor: Color(0xFFE4572E),
                title: "Meet & Greet",
                description:
                "Driver waits at arrivals with your\nname board.",
              ),

              SizedBox(height: context.hp(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class TransportCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;

  const TransportCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(context.wp(5)),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: const Color(0xFFE8E8EC),
          width: 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON CONTAINER
          Container(
            width: context.isTablet ? 72 : 64,
            height: context.isTablet ? 72 : 64,

            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(18),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: context.iconLarge,
            ),
          ),

          SizedBox(width: context.wp(5)),

          /// TEXT SECTION
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: context.hp(0.3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.sp(18),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF102347),
                    ),
                  ),

                  SizedBox(height: context.hp(1)),

                  /// DESCRIPTION
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: context.sp(14),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}