// import 'package:flutter/material.dart';
//
// class CustomBottomNav extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//
//   const CustomBottomNav({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       onTap: onTap,
//       type: BottomNavigationBarType.fixed,
//       selectedItemColor: Colors.blue,
//       items: const [
//         BottomNavigationBarItem(icon: Icon(Icons.flight), label: 'Flights'),
//         BottomNavigationBarItem(icon: Icon(Icons.hotel), label: 'Hotels'),
//         BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Visa'),
//         BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: 'Holidays'),
//         BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Transport'),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../views/Holidays/presentation/screen/holidays_screen.dart';
import '../views/Hotel/screen/hotel_screen.dart';
import '../views/Transport/screen/transport_screen.dart';
import '../views/home/presentation/screens/home_screen.dart';
import '../views/visa/presentation/screen/visa_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,

      type: BottomNavigationBarType.fixed,

      selectedItemColor: AppColors.primary,

      unselectedItemColor: Colors.grey,

      onTap: (index) {
        // HOME
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            ),
          );
        }

        // HOTELS
        else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const HotelBookingScreen(),
            ),
          );
        }
        // VISA
        else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const VisaScreen(),
            ),
          );
        }
        // HOLIDAY
        else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const HolidaysScreen(),
            ),
          );
        }

        // TRANSPORT
        else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const TransportBookingScreen(),
            ),
          );
        }
      },

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.flight),
          label: 'Flights',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.hotel),
          label: 'Hotels',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Visa',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.card_travel),
          label: 'Holidays',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Transport',
        ),
      ],
    );
  }
}