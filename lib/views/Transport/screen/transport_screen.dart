import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/Transport/sections/why_book.dart';

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

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const WanderNovaLogo(scaleFactor: 0.6),
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: 35,
            ),
          ),
        ],
      ),

      body: Container(
        color: const Color(0xFFF3F6FC),
        child: CustomScrollView(
          physics: context.scrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  context.w(10),
                  context.h(5),
                  context.w(10),
                  context.h(8),
                ),
                decoration: const BoxDecoration(color: Color(0xFFF3F6FC)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TransportBookingCard(
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
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: WhyBookTransportSection()),

            SliverToBoxAdapter(
              child: BlocProvider<ExclusiveDealsBloc>(
                create: (context) => sl<ExclusiveDealsBloc>(),
                child: const TransportExclusiveDealsSection(),
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

      bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
    );
  }
}
