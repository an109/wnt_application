import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
// WhyBookTransportSection doesn't match the redesigned Figma's section right
// below the search card (a multi-city promo banner there instead) — see the
// commented-out SliverToBoxAdapter below.
// import 'package:wander_nova/views/Transport/sections/why_book.dart';
import 'package:wander_nova/views/Transport/sections/transport_static_sections.dart';

import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/custom_drawer.dart';

import '../../../core/resources/app_colours.dart';
import '../../../injection_container.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../home/presentation/screen_sections/about_company_section.dart';
import '../../home/presentation/screen_sections/service_info_section.dart';
import '../../home/presentation/screens/deals.dart';
import '../../travel_stories/presentation/screen/travel_stories.dart';
import '../../home/presentation/screen_sections/faq/FAQ_section.dart';
import '../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../trending_route/presentation/screen/trending_routes.dart';
import '../../home/presentation/screen_sections/why_choose_us/why_choose_us.dart';
import '../../T_location/presentation/screen/booking_card.dart';

class TransportBookingScreen extends StatefulWidget {
  const TransportBookingScreen({super.key});

  @override
  State<TransportBookingScreen> createState() => _TransportBookingScreenState();
}

class _TransportBookingScreenState extends State<TransportBookingScreen> {
  bool isOneWay = true;

  DateTime selectedDate = DateTime.now();
  // DateTime selectedDate = DateTime.now();

  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      extendBodyBehindAppBar: true,

      body: Container(
        color: AppColors.white,
        child: CustomScrollView(
          physics: context.scrollPhysics,
          slivers: [
            // Full-bleed: no padding/margin so the hero image spans the
            // whole screen width, same as SearchCard on the flight screen.
            SliverToBoxAdapter(
              child: TransportBookingCard(
                isOneWay: isOneWay,
                selectedDate: selectedDate,
                selectedTime: selectedTime,
                onTripTypeChanged: (value) {
                  setState(() {
                    isOneWay = value;
                  });
                },
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
                onTimeChanged: (time) {
                  setState(() {
                    selectedTime = time;
                  });
                },
              ),
            ),

            // const SliverToBoxAdapter(child: WhyBookTransportSection()),
            const SliverToBoxAdapter(child: TransportMultiCityPromoSection()),
            const SliverToBoxAdapter(child: TransportWhatsNewSection()),
            const SliverToBoxAdapter(child: TransportOffersSection()),

            SliverToBoxAdapter(
              child: BlocProvider<ExclusiveDealsBloc>(
                create: (context) => sl<ExclusiveDealsBloc>(),
                child: const DealsSection(),
              ),
            ),

            const SliverToBoxAdapter(child: PopularDestinations()),

            const SliverToBoxAdapter(child: TrendingPackages()),

            SliverToBoxAdapter(
              child: BlocProvider(
                create: (_) =>
                    sl<GeneralSettingsBloc>()
                      ..add(const LoadFaqList(domain: 'thewandernova.com')),
                child: const FAQSection(),
              ),
            ),

            const SliverToBoxAdapter(child: TravelStoriesSection()),
            const SliverToBoxAdapter(child: WhyChooseUs()),

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
          ],
        ),
      ),

      // bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
    );
  }
}
