import 'package:flutter/material.dart';
import 'package:wander_nova/views/home/presentation/widgets/home_top_widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../common_widgets/custom_drawer.dart';
import '../../../injection_container.dart';
import '../../../hotelUIwidget/hotel_collections_section.dart';
import '../../../hotelUIwidget/hotel_luxe_packages_section.dart';
import '../../../hotelUIwidget/hotel_recent_searches_section.dart';
import '../../../hotelUIwidget/hotel_recently_viewed_section.dart';
import '../../../newUIWidgets/AIbutton.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../TrishaAI/presentation/screen/trisha_chat_screen.dart';
import '../../flight_popularDestination/presentation/screen/popular_destination.dart';
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
      create: (context) => sl<ExclusiveDealsBloc>(),
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
              const SliverToBoxAdapter(child: HotelRecentSearchesSection()),
              SliverToBoxAdapter(child: SizedBox(height: context.h(20))),
              const SliverToBoxAdapter(child: HotelCollectionsSection()),
              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),
              const SliverToBoxAdapter(child: HotelRecentlyViewedSection()),
              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                  child: const HomeOffersCarousel(categories: ['hotel']),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),
              const SliverToBoxAdapter(child: PopularDestinations()),
              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),
              const SliverToBoxAdapter(child: HotelLuxePackagesSection()),
              SliverToBoxAdapter(child: SizedBox(height: context.hp(10))),
            ],
          ),
          AIFloatingButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrishaChatScreen()),
              );
            },
          ),
        ],
      ),
      ),
      ),
    );
  }
}
