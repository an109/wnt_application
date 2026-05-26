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
                      height: context.isMobile ? context.hp(62) : context.hp(67),
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

                          return Container(
                            color: const Color(0xFFE0E0E0),
                          );
                        },
                      )
                      : Container(
                        color: const Color(0xFFE0E0E0),
                      ),
                    ),

                    // DARK OVERLAY
                    IgnorePointer(
                      ignoring: true,
                      child: Container(
                        height: context.isMobile ? context.hp(62) : context.hp(67),
                        color: Colors.black.withOpacity(0.30),
                      ),
                    ),

                    Positioned(
                      left: context.wp(1.2),
                      right: context.wp(1.5),
                      bottom: -context.hp(-4),
                      child: Material(
                        color: Colors.transparent,
                        child: SearchCard(),
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 18),
              ),

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
                  create: (_) => sl<GeneralSettingsBloc>()
                    ..add(const LoadFaqList(domain: 'thewandernova.com')),
                  child: const FAQSection(),
                ),
              ),
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