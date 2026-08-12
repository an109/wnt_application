import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../views/Holidays/presentation/screen/holidays_screen.dart';
import '../views/Hotel/screen/hotel_screen.dart';
import '../views/MMT_Holiday/screen/holiday_screen.dart';
import '../views/Transport/screen/transport_screen.dart';
import '../views/home/flight/flight_screen.dart';
import '../views/visa/presentation/screen/visa_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  // Helper method to build custom items with text labels
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = currentIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey,
          size: 26,
        ),
        // Only show text if the item is not flying up in active mode
        if (!isActive) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: context.labelSmall,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 63, // Increased slightly to give text labels breathing room
      backgroundColor: Colors.transparent,
      color: Colors.white,
      buttonBackgroundColor: AppColors.primary,
      animationDuration: const Duration(milliseconds: 300),

      items: [
        _buildNavItem(context, icon: Icons.flight, label: 'Flights', index: 0),
        _buildNavItem(context, icon: Icons.hotel, label: 'Hotels', index: 1),
        _buildNavItem(context, icon: Icons.assignment, label: 'Visa', index: 2),
        _buildNavItem(context, icon: Icons.card_travel, label: 'Holidays', index: 3),
        _buildNavItem(context, icon: Icons.directions_car, label: 'Transport', index: 4),
      ],

      onTap: (index) {
        if (index == currentIndex) return;

        // FLIGHTS
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FlightScreen()),
          );
        }
        // HOTELS
        else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
          );
        }
        // VISA
        else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VisaScreen()),
          );
        }
        // HOLIDAY
        else if (index == 3) {
          Navigator.pushReplacement(
            context,
            // MaterialPageRoute(builder: (_) => const NewHolidayScreen()),
            MaterialPageRoute(builder: (_) => const HolidaysScreen()),
          );
        }
        // TRANSPORT
        else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TransportBookingScreen()),
          );
        }
      },
    );
  }
}