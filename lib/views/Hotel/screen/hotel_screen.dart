import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../common_widgets/custom_drawer.dart';
import '../../../injection_container.dart';
import '../../../hotelUIwidget/hotel_collections_section.dart';
import '../../../hotelUIwidget/hotel_luxe_packages_section.dart';
import '../../../hotelUIwidget/hotel_recent_searches_section.dart';
import '../../../hotelUIwidget/hotel_recently_viewed_section.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';

import '../../flight_popularDestination/presentation/screen/popular_destination.dart';
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
    return BlocProvider<ExclusiveDealsBloc>(
      // Lifted above the whole screen (not just DealsSection) so
      // HotelCollectionsSection and HotelLuxePackagesSection can reuse the
      // same already-fetched real hotel deals instead of issuing their own
      // API calls — DealsSection's own dispatch below still fires exactly
      // once, they just listen to the same bloc instance.
      create: (context) => sl<ExclusiveDealsBloc>(),
      // White page now (no hero photo), so the status bar icons go dark.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
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
            const SliverToBoxAdapter(
              child: DealsSection(),
            ),


              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),

            const SliverToBoxAdapter(child: PopularDestinations()),
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

      ),
      ),
    );
  }
}