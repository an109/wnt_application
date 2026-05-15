import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../injection_container.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../../Hotel/section/exclusive_deals/travel_stories.dart';
import '../screen_sections/faq/FAQ_section.dart';
import '../screen_sections/popular_destination/popular_destination.dart';
import '../../../airport/presentation/screen/search_card.dart';
import '../screen_sections/trending_routes/trending_routes.dart';
import '../screen_sections/why_choose_us/why_choose_us.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

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
            padding: EdgeInsets.all(context.wp(2)),
            child: Image.asset(
              "assets/images/wander_nova_logo.jpg",
              height: context.hp(4.5),
            ),
          )
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
                  height: context.isMobile ? context.hp(65) : context.hp(70),
                  width: double.infinity,
                  child: Image.network(
                    "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=1200&auto=format&fit=crop",
                    fit: BoxFit.cover,
                  ),
                ),

                // DARK OVERLAY
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    height: context.isMobile ? context.hp(65) : context.hp(70),
                    color: Colors.black.withOpacity(0.30),
                  ),
                ),

                // TITLE
                Positioned(
                  top: context.hp(5),
                  left: context.wp(5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flight_takeoff,
                        color: Colors.white,
                        size: context.isMobile ? 32 : 40,
                      ),
                      SizedBox(width: context.wp(2.5)),
                      Text(
                        "Book Flights",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.isMobile ? 28 : 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  left: context.wp(4),
                  right: context.wp(4),
                  bottom: -context.hp(4),
                  child: Material(
                    color: Colors.transparent,
                    child: SearchCard(),
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),

          SliverToBoxAdapter(
            child: BlocProvider<ExclusiveDealsBloc>(
              create: (context) => sl<ExclusiveDealsBloc>(),
              child: const TransportExclusiveDealsSection(),
            ),
          ),

          const SliverToBoxAdapter(child: PopularDestinations()),
          const SliverToBoxAdapter(child: TrendingPackages()),
          const SliverToBoxAdapter(child: FAQSection()),
          const SliverToBoxAdapter(child: TravelStoriesSection()),
          const SliverToBoxAdapter(child: WhyChooseUs()),

          SliverToBoxAdapter(
            child: SizedBox(height: context.hp(5)),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 0,
      ),
    );
  }
}