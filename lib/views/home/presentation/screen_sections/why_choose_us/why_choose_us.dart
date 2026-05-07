import 'package:flutter/material.dart';

class WhyChooseUs extends StatelessWidget {
  const WhyChooseUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          /// Title
          const Text(
            "Why Choose Wander Nova?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          /// Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Your trusted partner for flights, hotels, holidays & visa — with great prices and support every step of the way.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;

              // Responsive: 2 cards mobile, 4 web/tablet
              int crossAxisCount = width < 600 ? 2 : 4;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                childAspectRatio: MediaQuery.of(context).size.width < 600 ? 0.75 : 0.9,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Icon Circle
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.red,
              size: 26,
            ),
          ),

          const SizedBox(height: 12),

          /// Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 8),

          /// Description
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}