import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/custom_drawer.dart';
import '../../../common_widgets/logo.dart';
import '../../../injection_container.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../home/presentation/screen_sections/about_company_section.dart';
import '../../home/presentation/screen_sections/service_info_section.dart';
import '../../home/presentation/screen_sections/why_choose_us/why_choose_us.dart';
import '../section/exclusive_deals/hotel_info.dart';
import '../section/exclusive_deals/hotel_search_card.dart';
import '../section/exclusive_deals/popular_destination.dart';
import '../../travel_stories/presentation/screen/travel_stories.dart';


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
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset("assets/images/wander_logo.png", height: 35),
          )
        ],
      ),
      body: CustomScrollView(
        physics: context.scrollPhysics,
        slivers: [

            /// SEARCH CARD (no background image — plain white)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.wp(2),
                  context.hp(1),
                  context.wp(2),
                  context.hp(2),
                ),
                child: const HotelSearchCard(),
              ),
            ),

            /// EXCLUSIVE DEALS SECTION
            SliverToBoxAdapter(
              child: BlocProvider<ExclusiveDealsBloc>(
                create: (context) => sl<ExclusiveDealsBloc>(),
                child: const TransportExclusiveDealsSection(),
              ),
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
              child: WhyChooseUs(),
            ),

            SliverToBoxAdapter(
              child: BlocProvider(
                create: (_) => sl<GeneralSettingsBloc>()
                  ..add(const LoadGeneralSettings(domain: 'thewandernova.com')),
                child: const AboutCompanySection(),
              ),
            ),

            SliverToBoxAdapter(
              child: BlocProvider(
                create: (_) => sl<GeneralSettingsBloc>()
                  ..add(const LoadGeneralSettings(domain: 'thewandernova.com')),
                child: const ServicesInfoSection(),
              ),
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