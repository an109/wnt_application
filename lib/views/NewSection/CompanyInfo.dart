import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class CompanyInformationSection extends StatelessWidget {
  const CompanyInformationSection({super.key});

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
                'assets/NewIcons/company_info.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.blue.shade50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business,
                          size: 60,
                          color: Colors.blue.shade300,
                        ),
                        SizedBox(height: 8),
                        Icon(
                          Icons.luggage,
                          size: 50,
                          color: const Color(0xff005B7F),
                        ),
                      ],
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
          // Content Overlay - Only on left side
          Positioned(
            left: context.wp(4),
            top: context.hp(4),
            bottom: context.hp(4),
            child: SizedBox(
              width: 220, // Fixed width for left content
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Company Information',
                    style: TextStyle(
                      fontSize: context.isMobile ? 24 : 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
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
                  SizedBox(height: 12),
                  // Description Text
                  Expanded(
                    child: Text(
                      'WANDER NOVA is one of the country\'s leading travel booking platforms, offering a full range of travel services including flight bookings, hotel reservations, visa assistance, holiday packages, travel insurance, and corporate travel solutions. With a customer-first approach and a strong digital platform, WANDER NOVA delivers reliable, convenient, and affordable travel solutions for both individuals and businesses. Whether you\'re travelling domestically or internationally, WANDER NOVA keeps your journey simple and stress-free.',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.justify,
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