import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../common_widgets/logo.dart';
import '../../../injection_container.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../travel_stories/presentation/screen/travel_stories.dart';
import '../presentation/screen_sections/faq/FAQ_section.dart';
import '../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../airport/presentation/screen/search_card.dart';
import '../../trending_route/presentation/screen/trending_routes.dart';
import '../presentation/screen_sections/why_choose_us/why_choose_us.dart';
import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/custom_drawer.dart';

class FlightScreen extends StatelessWidget {
  const FlightScreen({super.key});

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
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: context.h(36),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: CustomScrollView(
          physics: context.scrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(4),
                  context.h(2),
                  context.w(4),
                  context.h(14),
                ),
                child: const SearchCard(),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: context.h(4))),

            SliverToBoxAdapter(
              child: BlocProvider<ExclusiveDealsBloc>(
                create: (context) => sl<ExclusiveDealsBloc>(),
                child: const TransportExclusiveDealsSection(),
              ),
            ),

            const SliverToBoxAdapter(child: PopularDestinations()),
            const SliverToBoxAdapter(child: TrendingPackages()),
            // SliverToBoxAdapter(
            //   child: BlocProvider(
            //     create: (_) =>
            //         sl<GeneralSettingsBloc>()
            //           ..add(const LoadFaqList(domain: 'thewandernova.com')),
            //     child: const FAQSection(),
            //   ),
            // ),
            // const SliverToBoxAdapter(child: TravelStoriesSection()),
            // const SliverToBoxAdapter(child: WhyChooseUs()),
            //
            // SliverToBoxAdapter(child: SizedBox(height: context.h(40))),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }
}
