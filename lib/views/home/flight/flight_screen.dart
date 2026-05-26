import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../common_widgets/logo.dart';
import '../../../injection_container.dart';
import '../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../travel_stories/presentation/screen/travel_stories.dart';
import '../presentation/screen_sections/faq/FAQ_section.dart';
import '../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../airport/presentation/screen/search_card.dart';
import '../../trending_route/presentation/screen/trending_routes.dart';
import '../presentation/screen_sections/why_choose_us/why_choose_us.dart';
import '../../../common_widgets/custom_bottom_nav.dart';
import '../../../common_widgets/custom_drawer.dart';

class FlightScreen extends StatefulWidget {
  const FlightScreen({super.key});

  @override
  State<FlightScreen> createState() => _FlightScreenState();
}

class _FlightScreenState extends State<FlightScreen> {
  int currentIndex = 0;
  String? _flightHeroImage; // Store the flights hero image from API

  @override
  void initState() {
    super.initState();
    // Load section heroes data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GeneralSettingsBloc>()
            .add(const LoadSectionHeroes(domain: 'thewandernova.com'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeneralSettingsBloc, GeneralSettingsState>(
      listener: (context, state) {
        // Listen for SectionHeroesLoaded state to update background image
        if (state is SectionHeroesLoaded) {
          setState(() {
            _flightHeroImage = state.sectionHeroes.flights;
          });
        }
        if (state is GeneralSettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
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
        body: Container(
          color: const Color(0xFFF8F9FA),
          child: CustomScrollView(
            physics: context.scrollPhysics,
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // BACKGROUND IMAGE - Dynamic from API with fallback
                    SizedBox(
                      height: context.isMobile ? context.hp(65) : context.hp(70),
                      width: double.infinity,
                      child: _flightHeroImage != null && _flightHeroImage!.isNotEmpty
                          ? Image.network(
                        _flightHeroImage!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFE0E0E0),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {

                          // return Image.network(
                          //   "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=1200&auto=format&fit=crop",
                          //   fit: BoxFit.cover,
                          // );
                          return Container(
                            color: const Color(0xFFE0E0E0),
                          );
                        },
                      )
                      : Container(
                        color: const Color(0xFFE0E0E0),
                      ),
                      //     : Image.network(
                      //   "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=1200&auto=format&fit=crop",
                      //   fit: BoxFit.cover,
                      //   loadingBuilder: (context, child, loadingProgress) {
                      //     if (loadingProgress == null) return child;
                      //     return Container(
                      //       color: const Color(0xFFE0E0E0),
                      //       child: Center(
                      //         child: CircularProgressIndicator(
                      //           value: loadingProgress.expectedTotalBytes != null
                      //               ? loadingProgress.cumulativeBytesLoaded /
                      //               loadingProgress.expectedTotalBytes!
                      //               : null,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
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
                      top: context.hp(12.5),
                      left: context.wp(5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flight_takeoff,
                            color: Colors.white,
                            size: context.isMobile ? 28 : 36,
                          ),
                          SizedBox(width: context.wp(2.5)),
                          Text(
                            "Book Flights",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.isMobile ? 24 : 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      left: context.wp(1.5),
                      right: context.wp(1.5),
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
                child: SizedBox(height: 80),
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
        ),
        bottomNavigationBar: const CustomBottomNav(
          currentIndex: 0,
        ),
      ),
    );
  }
}