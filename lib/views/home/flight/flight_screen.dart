import 'package:flutter/material.dart';
import 'package:wander_nova/views/home/presentation/widgets/home_top_widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../injection_container.dart';
import '../../../newUIWidgets/AIbutton.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../TrishaAI/presentation/screen/trisha_chat_screen.dart';
import '../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../airport/presentation/screen/search_card.dart';
import '../../airport/presentation/screen/recent_searches_section.dart';
import '../../trending_route/presentation/screen/trending_routes.dart';
import '../../../common_widgets/custom_drawer.dart';


class FlightScreen extends StatelessWidget {
  const FlightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // White page now (no hero photo), so the status bar icons go dark.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Colors.white,
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
                    const SearchCard(),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: context.fx(32))),

              const SliverToBoxAdapter(child: RecentSearchesSection()),

              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),

              SliverToBoxAdapter(
                child: BlocProvider<ExclusiveDealsBloc>(
                  create: (context) => sl<ExclusiveDealsBloc>(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                    child: const HomeOffersCarousel(categories: ['flight']),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: context.h(24))),

              const SliverToBoxAdapter(child: PopularDestinations()),
              SliverToBoxAdapter(child: SizedBox(height: context.h(15))),
              const SliverToBoxAdapter(child: TrendingPackages()),
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
    );
  }
}
