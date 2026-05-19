// // lib/common_widgets/custom_bottom_nav.dart
// import 'package:flutter/material.dart';
// import 'package:wander_nova/core/resources/app_colours.dart';
//
// import '../views/home/presentation/screens/Account_screen.dart';
// import '../views/home/presentation/screens/credit_card_screen.dart';
// import '../views/home/presentation/screens/home_screen.dart';
// import '../views/home/presentation/screens/my_trip_screen.dart';
// import '../views/home/presentation/screens/offers_screen.dart';
//
//
// class NewBottomNav extends StatelessWidget {
//   final int currentIndex;
//
//   const NewBottomNav({
//     super.key,
//     required this.currentIndex,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       type: BottomNavigationBarType.fixed,
//       selectedItemColor: AppColors.primary,
//       unselectedItemColor: Colors.grey[600],
//       backgroundColor: Colors.white,
//       elevation: 8,
//       showSelectedLabels: true,
//       showUnselectedLabels: true,
//       selectedLabelStyle: TextStyle(
//         fontSize: 11,
//         fontWeight: FontWeight.w600,
//       ),
//       unselectedLabelStyle: TextStyle(
//         fontSize: 10,
//         fontWeight: FontWeight.w400,
//       ),
//       onTap: (index) {
//         if (index == currentIndex) return;
//
//         switch (index) {
//           case 0: // HOME
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const HomeScreen()),
//             );
//             break;
//           case 1: // MY TRIPS
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const MyTripsScreen()),
//             );
//             break;
//           case 2: // CREDIT CARD
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const CreditCardScreen()),
//             );
//             break;
//           case 3: // OFFERS
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const OffersScreen()),
//             );
//             break;
//           case 4: // ACCOUNT
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const AccountScreen()),
//             );
//             break;
//         }
//       },
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home_outlined),
//           activeIcon: Icon(Icons.home_filled),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.luggage_outlined),
//           activeIcon: Icon(Icons.luggage),
//           label: 'My Trips',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.credit_card_outlined),
//           activeIcon: Icon(Icons.credit_card),
//           label: 'Credit Card',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.local_offer_outlined),
//           activeIcon: Icon(Icons.local_offer),
//           label: 'Offers',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person_outline),
//           activeIcon: Icon(Icons.person),
//           label: 'Account',
//         ),
//       ],
//     );
//   }
// }


// lib/common_widgets/custom_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import package
import 'package:wander_nova/core/resources/app_colours.dart';

import '../views/home/presentation/screens/Account_screen.dart';
import '../views/home/presentation/screens/credit_card_screen.dart';
import '../views/home/presentation/screens/home_screen.dart';
import '../views/home/presentation/screens/my_trip_screen.dart';
import '../views/home/presentation/screens/offers_screen.dart';

class NewBottomNav extends StatelessWidget {
  final int currentIndex;

  const NewBottomNav({
    super.key,
    required this.currentIndex,
  });

  // Helper method to build an animated navigation cell
  Widget _buildAnimatedItem({
    required IconData inactiveIcon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final bool isActive = currentIndex == index;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Icon Layer with Pop & Scale Animation
          Icon(
            isActive ? activeIcon : inactiveIcon,
            color: isActive ? AppColors.primary : Colors.grey[600],
            size: 24,
          )
              .animate(target: isActive ? 1 : 0) // Dynamically triggers animation on state switch
              .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 200.ms, curve: Curves.easeOutBack)
              .slideY(begin: 0, end: -0.15, duration: 200.ms), // Gently elevates the active icon

          const SizedBox(height: 4),

          // 2. Text Title Layer with smooth color transformation
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isActive ? 11 : 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : Colors.grey[600],
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 200.ms),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Premium floating layout with a soft shadow injection
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4), // Drops shadow upward above the bar
          ),
        ],
      ),
      child: SafeArea(
        top: false, // Prevents pushing layout unnecessarily down on bezel-less phones
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleNavigation(context, 0),
              child: _buildAnimatedItem(
                inactiveIcon: Icons.home_outlined,
                activeIcon: Icons.home_filled,
                label: 'Home',
                index: 0,
              ),
            ),
            // Tab 1
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleNavigation(context, 1),
              child: _buildAnimatedItem(
                inactiveIcon: Icons.luggage_outlined,
                activeIcon: Icons.luggage,
                label: 'My Trips',
                index: 1,
              ),
            ),
            // Tab 2
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleNavigation(context, 2),
              child: _buildAnimatedItem(
                inactiveIcon: Icons.credit_card_outlined,
                activeIcon: Icons.credit_card,
                label: 'Credit Card',
                index: 2,
              ),
            ),
            // Tab 3
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleNavigation(context, 3),
              child: _buildAnimatedItem(
                inactiveIcon: Icons.local_offer_outlined,
                activeIcon: Icons.local_offer,
                label: 'Offers',
                index: 3,
              ),
            ),
            // Tab 4
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleNavigation(context, 4),
              child: _buildAnimatedItem(
                inactiveIcon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Account',
                index: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Extracted clean routing method
  void _handleNavigation(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyTripsScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreditCardScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OffersScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
        break;
    }
  }
}
