import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/custom_drawer.dart';
import '../../../common_widgets/logo.dart';
import '../../home/presentation/screens/home_screen.dart';
import '../section/exclusive_deals/company_info.dart';
import '../section/exclusive_deals/excllusive_deal_section.dart';
import '../section/exclusive_deals/hotel_info.dart';
import '../section/exclusive_deals/hotel_search_card.dart';
import '../section/exclusive_deals/popular_destination.dart';
import '../section/exclusive_deals/travel_stories.dart';
import '../section/exclusive_deals/why_choose.dart';

class HotelBookingScreen extends StatelessWidget {
  const HotelBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset("assets/images/wander_nova_logo.jpg", height: 35),
          )
        ],
      ),
      body: CustomScrollView(
        physics: context.scrollPhysics,
        slivers: [

          /// TOP IMAGE + SEARCH CARD
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                /// BACKGROUND IMAGE
                SizedBox(
                  height: context.hp(65),
                  width: double.infinity,
                  child: Image.network(
                    "https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1200&auto=format&fit=crop",
                    fit: BoxFit.cover,
                  ),
                ),

                /// DARK OVERLAY
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    height: context.hp(55),
                    color: Colors.black.withOpacity(0.25),
                  ),
                ),

                /// TITLE
                Positioned(
                  top: context.hp(6),
                  left: context.wp(5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hotel,
                        color: Colors.white,
                        size: context.iconLarge,
                      ),

                      SizedBox(width: context.gapSmall),

                      Text(
                        "Book Hotel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                /// SEARCH CARD
                Positioned(
                  left: context.wp(4),
                  right: context.wp(4),
                  bottom: -context.hp(-2),
                  child: Material(
                    color: Colors.transparent,
                    child: HotelSearchCard(),
                  ),
                ),
              ],
            ),
          ),

          /// SPACE BELOW OVERLAPPING CARD
          SliverToBoxAdapter(
            child: SizedBox(height: context.hp(4)),
          ),

          /// EXCLUSIVE DEALS SECTION
          const SliverToBoxAdapter(
            child: HotelExclusiveDealsSection(),
          ),

          const SliverToBoxAdapter(
            child: HotelPopularDestinationsSection(),
          ),

          const SliverToBoxAdapter(
            child: TravelStoriesSection(),
          ),

          const SliverToBoxAdapter(
            child: HotelInfoSection(),
          ),

          const SliverToBoxAdapter(
            child: WhyChooseWanderNova(),
          ),

          const SliverToBoxAdapter(
            child: CompanyInformationSection(),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: context.hp(10)),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 1,
      ),
    );
  }
}