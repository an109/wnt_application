import 'package:flutter/material.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';

/// Floating "Map / Sort / Filter" bar + AI orb, styled after
/// FlightSearchScreen's `_buildOneWayActionBar` (same pill shape, divider,
/// shadow and `assets/Newgif/home_ai.gif` orb) so hotel results and flight
/// results share one visual language for their bottom chrome.
class AkHotelBottomBar extends StatelessWidget {
  final VoidCallback onMapTap;
  final VoidCallback onSortTap;
  final VoidCallback onFilterTap;
  final VoidCallback onAiTap;
  final bool sortActive;
  final bool filterActive;

  const AkHotelBottomBar({
    super.key,
    required this.onMapTap,
    required this.onSortTap,
    required this.onFilterTap,
    required this.onAiTap,
    this.sortActive = false,
    this.filterActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(6),
          context.w(16),
          context.h(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: context.h(44.8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(context.r(30)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff2B3A67).withValues(alpha: 0.12),
                      blurRadius: context.w(15),
                      offset: Offset(0, context.h(4)),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _barButton(
                        context,
                        iconPath: 'assets/Newimage/mapIcon.png',
                        label: 'Map',
                        onTap: onMapTap,
                      ),
                    ),
                    _divider(context),
                    Expanded(
                      child: _barButton(
                        context,
                        iconPath: 'assets/NewIcons/sort.png',
                        label: 'Sort',
                        active: sortActive,
                        onTap: onSortTap,
                      ),
                    ),
                    _divider(context),
                    Expanded(
                      child: _barButton(
                        context,
                        iconPath: 'assets/NewIcons/filter.png',
                        label: 'Filter',
                        active: filterActive,
                        onTap: onFilterTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: context.w(12)),
            GestureDetector(
              onTap: onAiTap,
              child: Container(
                width: context.w(48),
                height: context.h(48),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/Newgif/ai_frame.png',
                        width: context.w(60),
                        height: context.h(60),
                        fit: BoxFit.cover,
                      ),
                    ),
                    ClipOval(
                      child: Image.asset(
                        'assets/Newgif/home_ai.gif',
                        width: context.w(62),
                        height: context.h(62),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(width: 1, height: context.h(20), color: const Color(0xffE6ECFF));
  }

  Widget _barButton(
    BuildContext context, {
    // required IconData icon,
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final color = active ? AppColors.AppBlue : AppColors.black;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: context.w(16),
            height: context.w(16),
            fit: BoxFit.contain,
          ),
          SizedBox(width: context.w(6)),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
