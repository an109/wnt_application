import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final VoidCallback? onCenterTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [

          // ============================================================
          // FROSTED GLASS BOTTOM NAVIGATION
          // ============================================================

          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 18,
                  sigmaY: 18,
                ),
                child: Container(
                  height: 64,

                  // ONE transparent glass background
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(40),

                    // Very subtle border like Figma glass effect
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 18,
                        spreadRadius: 0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      // ==================================================
                      // HOME
                      // ==================================================

                      Expanded(
                        child: _NavItem(
                          icon: 'assets/NewIcons/homeHD.png',
                          label: 'Home',
                          selected: currentIndex == 0,
                          onTap: () {
                            onItemSelected(0);
                          },
                        ),
                      ),

                      // ==================================================
                      // TRIP
                      // ==================================================

                      Expanded(
                        child: _NavItem(
                          icon: 'assets/NewIcons/tripHD.png',
                          label: 'Trip',
                          selected: currentIndex == 1,
                          onTap: () {
                            onItemSelected(1);
                          },
                        ),
                      ),

                      // ==================================================
                      // CENTER AI SPACE
                      // ==================================================

                      const SizedBox(
                        width: 64,
                      ),

                      // ==================================================
                      // BOOKING
                      // ==================================================

                      Expanded(
                        child: _NavItem(
                          icon: 'assets/NewIcons/bookingHD.png',
                          label: 'Booking',
                          selected: currentIndex == 2,
                          onTap: () {
                            onItemSelected(2);
                          },
                        ),
                      ),

                      // ==================================================
                      // OFFER
                      // ==================================================

                      Expanded(
                        child: _NavItem(
                          icon: 'assets/NewIcons/offerHD.png',
                          label: 'Offer',
                          selected: currentIndex == 3,
                          onTap: () {
                            onItemSelected(3);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // CENTER AI BUTTON
          // ============================================================

          Positioned(
            top: -9,
            child: GestureDetector(
              onTap: onCenterTap,
              child: Container(
                width: 54,
                height: 54,

                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),

                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    // ==================================================
                    // COLORFUL AI FRAME
                    // ==================================================

                    ClipOval(
                      child: Image.asset(
                        'assets/Newgif/ai_frame.png',
                        width: 53,
                        height: 53,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // ==================================================
                    // AI GIF
                    // ==================================================

                    ClipOval(
                      child: Image.asset(
                        'assets/Newgif/home_ai.gif',
                        width: 65,
                        height: 65,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ======================================================================
// NAVIGATION ITEM
// ======================================================================

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemColor = selected
        ? AppColors.AppBlue
        : const Color(0xFF6D6D6D);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // ============================================================
          // ICON
          // ============================================================

          Image.asset(
            icon,
            width: 25,
            height: 25,
            fit: BoxFit.contain,
            color: itemColor,
          ),

          const SizedBox(
            height: 3,
          ),

          // ============================================================
          // LABEL
          // ============================================================

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected
                  ? FontWeight.w500
                  : FontWeight.w400,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }
}