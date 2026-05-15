import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/custom_drawer.dart';
import '../../../../common_widgets/logo.dart';
import '../section/holiday_banner_section.dart';


class HolidaysScreen extends StatelessWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: WanderNovaLogo(
          scaleFactor: context.isMobile ? 0.6 : (context.isTablet ? 0.8 : 1.0),
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.wp(2)),
            child: Image.asset(
              "assets/images/wander_nova_logo.jpg",
              height: context.hp(4.5),
            ),
          )
        ],
      ),

      body: CustomScrollView(
        physics: context.scrollPhysics,

        slivers: [

          /// TOP BANNER + SEARCH CARD
          const SliverToBoxAdapter(
            child: HolidaysBannerSection(),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: context.hp(5),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 3,
      ),
    );
  }


  Widget _topButton(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
      }) {

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.gapMedium,
        vertical: context.gapSmall,
      ),

      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: Colors.white,
            size: context.iconSmall,
          ),

          SizedBox(width: context.gapSmall),

          Text(
            title,

            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// =============================================
  /// CURRENCY BUTTON
  /// =============================================

  Widget _currencyButton(BuildContext context) {

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.gapMedium,
        vertical: context.gapSmall,
      ),

      decoration: BoxDecoration(
        color: const Color(0xff2143D6),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        children: [

          const Text(
            "🇮🇳",
            style: TextStyle(fontSize: 18),
          ),

          SizedBox(width: context.gapSmall),

          Text(
            "IND | ₹ INR",

            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.bodySmall,
            ),
          ),

          SizedBox(width: context.gapSmall),

          const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }

  /// =============================================
  /// PROFILE BUTTON
  /// =============================================

  Widget _profileButton(BuildContext context) {

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.gapMedium,
        vertical: context.gapSmall,
      ),

      decoration: BoxDecoration(
        color: const Color(0xff16A34A),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        children: [

          Icon(
            Icons.person_outline,
            color: Colors.white,
            size: context.iconSmall,
          ),

          SizedBox(width: context.gapSmall),

          Text(
            "Hi Anisha",

            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.bodySmall,
            ),
          ),

          SizedBox(width: context.gapSmall),

          const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}