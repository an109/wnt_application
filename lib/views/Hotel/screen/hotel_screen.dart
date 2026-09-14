import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../common_widgets/custom_drawer.dart';
import '../../../injection_container.dart';
import '../../../hotelUIwidget/hotel_collections_section.dart';
import '../../../hotelUIwidget/hotel_luxe_packages_section.dart';
import '../../../hotelUIwidget/hotel_recent_searches_section.dart';
import '../../../hotelUIwidget/hotel_recently_viewed_section.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';

import '../../home/presentation/screens/deals.dart';
import '../section/exclusive_deals/hotel_search_card.dart';


class HotelBookingScreen extends StatefulWidget {
  const HotelBookingScreen({super.key});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
        CustomScrollView(
          physics: context.scrollPhysics,
          slivers: [

            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const HotelSearchCard(),

                  // Figma: Rectangle 35
                  // Fill: #FFFFFF
                  // Layer Blur: 16
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -context.h(15),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 16,
                        sigmaY: 16,
                      ),
                      child: Container(
                        height: context.h(30),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              SliverToBoxAdapter(child: SizedBox(height: context.h(12))),

              /// RECENT SEARCHES SECTION (Figma 137:1117)
              const SliverToBoxAdapter(
                child: HotelRecentSearchesSection(),
              ),
              SliverToBoxAdapter(child: SizedBox(height: context.h(20))),




              /// COLLECTIONS SECTION (Figma 137:1117)
              const SliverToBoxAdapter(
                child: HotelCollectionsSection(),
              ),
              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),

              /// RECENTLY VIEWED SECTION (Figma 137:1117)
              const SliverToBoxAdapter(
                child: HotelRecentlyViewedSection(),
              ),
              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),

            /// EXCLUSIVE DEALS / AD BANNER SECTION
            SliverToBoxAdapter(
              child: BlocProvider<ExclusiveDealsBloc>(
                create: (context) => sl<ExclusiveDealsBloc>(),
                child: const DealsSection(),
              ),
            ),


              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),

              /// LUXE - BEST PACKAGES SECTION (Figma 137:1117)
              const SliverToBoxAdapter(
                child: HotelLuxePackagesSection(),
              ),


              SliverToBoxAdapter(
                child: SizedBox(height: context.hp(10)),
              ),
            ],
          ),
          Positioned(
            bottom: context.h(56), // Adjust as needed
            right: context.w(20), // Adjust as needed
            child: GestureDetector(
              onTap: () {
                // Handle AI button tap
                debugPrint("AI button tapped in FlightScreen");
                // Add your AI functionality here
              },
              child: Container(
                width: context.w(50),
                height: context.h(50),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
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
                        width: context.w(63),
                        height: context.h(63),
                        fit: BoxFit.cover,
                      ),
                    ),
                    // ==================================================
                    // AI GIF
                    // ==================================================
                    ClipOval(
                      child: Image.asset(
                        'assets/Newgif/home_ai.gif',
                        width: context.w(65),
                        height: context.h(65),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ]
      ),

    );
  }
}