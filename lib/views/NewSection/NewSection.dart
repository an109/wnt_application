import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class WhyWanderNovaSection extends StatelessWidget {
  const WhyWanderNovaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      height: 207,
      margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),

      ),
      child: Stack(
        children: [
          // Full Background Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 207,
              width: 380,
              child: Image.asset(
                'assets/NewIcons/nova.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.blue.shade100,
                    child: Icon(
                      Icons.airplanemode_active,
                      size: 80,
                      color: Colors.blue.shade300,
                    ),
                  );
                },
              ),
            ),
          ),
          // Gradient Overlay - Light on left, transparent on right
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Content Overlay
          Positioned(
            left: context.wp(3),
            top: context.hp(4),
            bottom: context.hp(4),
            child: SizedBox(
                width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Why ',
                          style: TextStyle(
                            fontSize: context.isMobile ? 24 : 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: 'Wander ',
                          style: TextStyle(
                            fontSize: context.isMobile ? 24 : 30,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff005B7F),
                          ),
                        ),
                        TextSpan(
                          text: 'Nova ',
                          style: TextStyle(
                            fontSize: context.isMobile ? 24 : 30,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xffFF6B00),
                          ),
                        ),
                        TextSpan(
                          text: '?',
                          style: TextStyle(
                            fontSize: context.isMobile ? 24 : 30,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff005B7F),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Decorative line
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: const Color(0xff005B7F),
                        ),
                      ),
                       Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Image.asset(
                          'assets/NewIcons/flight.png',
                          width: 14,
                          height: 14,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: const Color(0xffFF6B00),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Expanded(
                    child: Text(
                      'WANDER NOVA brings unbeatable value with daily flight deals, '
                          'exclusive discounts, seasonal offers and one of the widest selections of flights,'
                          ' hotels, and holiday packages. Travellers can compare fares across multiple airlines, '
                          'explore different flights and choose from countless stay options worldwide.'
                          ' Add visa services, sightseeing activities, and travel insurance, browse multiple tour packages - all in one place. '
                          'You get a complete travel hub designed to simplify every part of your journey. '
                          'Whether you\'re planning a family vacation, business trip, or last-minute getaway,'
                          ' WANDER NOVA offers real-time availability, secure payments, and smooth navigation, '
                          'ensuring a hassle-free booking experience every single time.',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.left,
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
