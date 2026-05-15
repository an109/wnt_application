import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/custom_drawer.dart';
import '../../../../common_widgets/logo.dart';
import '../../../Hotel/section/exclusive_deals/travel_stories.dart';
import '../../../home/presentation/screen_sections/why_choose_us/why_choose_us.dart';
import '../sections/popular_visa_destination.dart';
import '../sections/visa_banner_section.dart';
import '../sections/visa_process_section.dart';

class VisaScreen extends StatelessWidget {
  const VisaScreen({super.key});

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
            child: VisaBannerSection(),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: context.hp(2)),
          ),

          /// POPULAR DESTINATIONS
          const SliverToBoxAdapter(
            child: PopularVisaDestinations(),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: context.hp(0.3)),
          ),
          const SliverToBoxAdapter(child: VisaProcessSection()),
          const SliverToBoxAdapter(child: WhyChooseUs()),
          const SliverToBoxAdapter(child: TravelStoriesSection()),


          SliverToBoxAdapter(
            child: SizedBox(height: context.hp(4)),
          ),
        ],
      ),

      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 2,
      ),
    );
  }
}