// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
// import '../../../common_widgets/logo.dart';
// import '../../../injection_container.dart';
// import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
// import '../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
// import '../../MainApi/presentation/bloc/general_setting_bloc.dart';
// import '../../MainApi/presentation/bloc/general_settings_event.dart';
// import '../../travel_stories/presentation/screen/travel_stories.dart';
// import '../presentation/screen_sections/faq/FAQ_section.dart';
// import '../../flight_popularDestination/presentation/screen/popular_destination.dart';
// import '../../airport/presentation/screen/search_card.dart';
// import '../../airport/presentation/screen/recent_searches_section.dart';
// import '../../trending_route/presentation/screen/trending_routes.dart';
// import '../presentation/screen_sections/why_choose_us/why_choose_us.dart';
// import '../../../common_widgets/custom_bottom_nav.dart';
// import '../../../common_widgets/custom_drawer.dart';
// import '../presentation/screens/deals.dart';
//
// class FlightScreen extends StatelessWidget {
//   const FlightScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const CustomDrawer(),
//       extendBodyBehindAppBar: true,
//       body: Container(
//         color: const Color(0xFFFFFFFF),
//         child: CustomScrollView(
//           physics: context.scrollPhysics,
//           slivers: [
//             // Full-bleed hero + search form: no padding/margin at all so the
//             // background image spans the whole screen width.
//             const SliverToBoxAdapter(child: SearchCard()),
//
//             SliverToBoxAdapter(child: SizedBox(height: context.h(18))),
//
//             // Recent Searches — reads back whatever SearchCard already
//             // saved to PreferencesManager; hides itself when there's none.
//             const SliverToBoxAdapter(child: RecentSearchesSection()),
//
//             SliverToBoxAdapter(child: SizedBox(height: context.h(12))),
//
//             SliverToBoxAdapter(
//               child: BlocProvider<ExclusiveDealsBloc>(
//                 create: (context) => sl<ExclusiveDealsBloc>(),
//                 child: const DealsSection(),
//               ),
//             ),
//
//             const SliverToBoxAdapter(child: PopularDestinations()),
//             const SliverToBoxAdapter(child: TrendingPackages()),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../injection_container.dart';
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
                const SliverToBoxAdapter(child: SearchCard()),

                SliverToBoxAdapter(child: SizedBox(height: context.h(18))),

                // Recent Searches — reads back whatever SearchCard already
                // saved to PreferencesManager; hides itself when there's none.
                const SliverToBoxAdapter(child: RecentSearchesSection()),

                SliverToBoxAdapter(child: SizedBox(height: context.h(12))),

                SliverToBoxAdapter(
                  child: BlocProvider<ExclusiveDealsBloc>(
                    create: (context) => sl<ExclusiveDealsBloc>(),
                    child: const DealsSection(),
                  ),
                ),

                const SliverToBoxAdapter(child: PopularDestinations()),
                const SliverToBoxAdapter(child: TrendingPackages()),
              ],
            ),
          ),

          // ==================================================
          // FLOATING AI BUTTON - Fixed at bottom right
          // ==================================================
          Positioned(
            bottom: context.h(30), // Adjust as needed
            right: context.w(20), // Adjust as needed
            child: GestureDetector(
              onTap: () {
                // Handle AI button tap
                debugPrint("AI button tapped in FlightScreen");
                // Add your AI functionality here
              },
              child: Container(
                width: context.w(44),
                height: context.h(44),
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
        ],
      ),
    );
  }
}
