import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../injection_container.dart';
import '../../../newUIWidgets/AIbutton.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../airport/presentation/screen/search_card.dart';
import '../../airport/presentation/screen/recent_searches_section.dart';
import '../../trending_route/presentation/screen/trending_routes.dart';
import '../../../common_widgets/custom_drawer.dart';
import '../presentation/screens/deals.dart';

class FlightScreen extends StatelessWidget {
  const FlightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main content
          Container(
            color: const Color(0xFFFFFFFF),
            child: CustomScrollView(
              physics: context.scrollPhysics,
              slivers: [
                // Full-bleed hero + search form: no padding/margin at all so the
                // background image spans the whole screen width.
                // const SliverToBoxAdapter(child: SearchCard()),
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const SearchCard(),

                      // Figma: Rectangle 35
                      // Fill: #FFFFFF
                      // Layer Blur: 16
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -context.h(25),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 16,
                            sigmaY: 16,
                          ),
                          child: Container(
                            height: context.h(40),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: context.h(18))),

                // Recent Searches — reads back whatever SearchCard already
                // saved to PreferencesManager; hides itself when there's none.
                const SliverToBoxAdapter(child: RecentSearchesSection()),

                SliverToBoxAdapter(child: SizedBox(height: context.h(24))),

                SliverToBoxAdapter(
                  child: BlocProvider<ExclusiveDealsBloc>(
                    create: (context) => sl<ExclusiveDealsBloc>(),
                    child: const DealsSection(),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: context.h(24))),

                const SliverToBoxAdapter(child: PopularDestinations()),
                SliverToBoxAdapter(child: SizedBox(height: context.h(15))),
                const SliverToBoxAdapter(child: TrendingPackages()),
              ],
            ),
          ),

          // ==================================================
          // FLOATING AI BUTTON - Fixed at bottom right
          // ==================================================
          AIFloatingButton(
            onTap: () {},
          )
        ],
      ),
    );
  }
}
