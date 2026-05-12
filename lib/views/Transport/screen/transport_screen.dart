import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/Transport/sections/why_book.dart';

import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/custom_drawer.dart';
import '../../../common_widgets/logo.dart';

import '../../Hotel/section/exclusive_deals/company_info.dart';
import '../../Hotel/section/exclusive_deals/excllusive_deal_section.dart';
import '../../Hotel/section/exclusive_deals/travel_stories.dart';
import '../../home/presentation/screen_sections/faq/FAQ_section.dart';
import '../../home/presentation/screen_sections/popular_destination/popular_destination.dart';
import '../../home/presentation/screen_sections/trending_routes/trending_routes.dart';
import '../../home/presentation/screen_sections/why_choose_us/why_choose_us.dart';
import '../sections/booking_card.dart';

class TransportBookingScreen extends StatefulWidget {
  const TransportBookingScreen({super.key});

  @override
  State<TransportBookingScreen> createState() =>
      _TransportBookingScreenState();
}

class _TransportBookingScreenState
    extends State<TransportBookingScreen> {

  bool isOneWay = true;

  DateTime selectedDate = DateTime(2026, 5, 11);
  // DateTime selectedDate = DateTime.now();

  TimeOfDay selectedTime =
  const TimeOfDay(hour: 9, minute: 0);

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
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "assets/images/wander_nova_logo.jpg",
              height: 35,
            ),
          ),
        ],
      ),

      body: CustomScrollView(
        physics: context.scrollPhysics,
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                // BACKGROUND IMAGE
                SizedBox(
                  height: context.hp(84),
                  width: double.infinity,
                  child: Image.network(
                    "https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1200&auto=format&fit=crop",
                    fit: BoxFit.cover,
                  ),
                ),

                // OVERLAY
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    height: context.hp(72),
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),

                // TOP TEXT
                Positioned(
                  top: context.hp(6),
                  left: context.wp(6),
                  right: context.wp(6),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      SizedBox(
                        width: context.wp(75),
                        child: Text(
                          "Comfortable\nRides,\nOn Time, Every\nTime",
                          style: TextStyle(
                            fontSize: context.sp(24),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xff0D2B5C),
                            height: 1.1,
                          ),
                        ),
                      ),

                      SizedBox(height: context.hp(2)),

                      Text(
                        "Airport transfers, city rides,\nintercity travel and more.",
                        style: TextStyle(
                          fontSize: context.bodyLarge,
                          color: const Color(0xff1F2A44),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // BOOKING CARD
                Positioned(
                  left: context.wp(4),
                  right: context.wp(4),
                  bottom: -context.hp(10),

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
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: context.hp(12)),
          ),


          const SliverToBoxAdapter(
            child: WhyBookTransportSection(),
          ),

          const SliverToBoxAdapter(
            child: HotelExclusiveDealsSection(),
          ),

          const SliverToBoxAdapter(
              child: PopularDestinations()
          ),

          const SliverToBoxAdapter(
              child: TrendingPackages()
          ),

          const SliverToBoxAdapter(
              child: FAQSection()
          ),

          const SliverToBoxAdapter(child: TravelStoriesSection()),
          const SliverToBoxAdapter(child: WhyChooseUs()),

          const SliverToBoxAdapter(
            child: CompanyInformationSection(),
          ),

        ],
      ),

      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 4,
      ),
    );
  }
}