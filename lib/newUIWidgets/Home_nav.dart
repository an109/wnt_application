import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/views/TrishaAI/presentation/widgets/trisha_style.dart';

/// Home bottom bar from the "MAIN HOME" Figma frame: Home, Trip, the AI
/// button, Offer and Wishlist (indices 0–3, AI excluded).
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

  static const _items = [
    ('assets/home/nav_home.svg', 'Home'),
    ('assets/home/nav_trip.svg', 'Trip'),
    ('assets/home/nav_offer.svg', 'Offer'),
    ('assets/home/nav_wishlist.svg', 'Wishlist'),
  ];

  @override
  Widget build(BuildContext context) {
    final barHeight = context.fx(64);
    final aiSize = context.fx(52);
    // The AI button is centred on the bar's top edge.
    final overhang = aiSize / 2;

    Widget item(int i) => Expanded(
      child: _NavItem(
        icon: _items[i].$1,
        label: _items[i].$2,
        selected: currentIndex == i,
        onTap: () => onItemSelected(i),
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: barHeight + overhang,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ============================================================
          // FROSTED GLASS BAR
          // ============================================================
          Positioned(
            left: context.fx(16),
            right: context.fx(16),
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.fx(44)),
                // Soft lift rather than a dark smudge under the bar.
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.fx(44)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  // Frosted glass: mostly-white so the grey/blue icons stay
                  // readable over dark photos, still blurring what's behind.
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(context.fx(44)),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    child: Row(
                      children: [
                        item(0),
                        item(1),
                        SizedBox(width: context.fx(64)), // AI button slot
                        item(2),
                        item(3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // CENTER AI BUTTON — the Trisha orb with its soft blue halo
          // ============================================================
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onCenterTap,
              child: Container(
                width: aiSize,
                height: aiSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: context.fx(4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x4D4A9FE8),
                      blurRadius: context.fx(40),
                      spreadRadius: context.fx(12),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    TrishaStyle.orbAsset,
                    fit: BoxFit.cover,
                    // Until the orb is exported from Figma, keep the old animation.
                    errorBuilder: (_, __, ___) => Image.asset('assets/Newgif/home_ai.gif', fit: BoxFit.cover),
                  ),
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
        : const Color(0xFF757575);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            width: context.fx(24),
            height: context.fx(24),
            colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
          ),
          SizedBox(height: context.fx(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.ffs(10),
              fontWeight: FontWeight.w500,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }
}
