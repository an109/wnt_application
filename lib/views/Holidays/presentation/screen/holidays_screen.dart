import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/custom_drawer.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../injection_container.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../home/presentation/screen_sections/about_company_section.dart';
import '../../../home/presentation/screen_sections/service_info_section.dart';
import '../../../travel_stories/presentation/screen/travel_stories.dart';

import '../widget/holiday_search_card.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  String? _holidayHeroImage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GeneralSettingsBloc>().add(
          const LoadSectionHeroes(domain: 'thewandernova.com'),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GeneralSettingsBloc, GeneralSettingsState>(
      listener: (context, state) {
        if (state is SectionHeroesLoaded) {
          setState(() {
            _holidayHeroImage = state.sectionHeroes.holidays;
          });
        }

        if (state is GeneralSettingsError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        drawer: const CustomDrawer(),

        appBar: AppBar(
          title: WanderNovaLogo(
            scaleFactor: context.isMobile
                ? 0.6
                : (context.isTablet ? 0.8 : 1.0),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: EdgeInsets.all(context.wp(2)),
              child: Image.asset(
                "assets/images/wander_nova_logo.jpg",
                height: context.hp(4.5),
              ),
            ),
          ],
        ),

        body: Container(
          color: const Color(0xFFF8F9FA),

          child: CustomScrollView(
            physics: context.scrollPhysics,

            slivers: [
              /// HERO SECTION
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    /// BACKGROUND IMAGE
                    SizedBox(
                      height: context.isMobile
                          ? context.hp(65)
                          : context.hp(70),
                      width: double.infinity,
                      child:
                          _holidayHeroImage != null &&
                              _holidayHeroImage!.isNotEmpty
                          ? Image.network(
                              _holidayHeroImage!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: const Color(0xFFE0E0E0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
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
                          : Container(color: const Color(0xFFE0E0E0)),
                    ),

                    /// DARK OVERLAY
                    IgnorePointer(
                      ignoring: true,

                      child: Container(
                        height: context.isMobile
                            ? context.hp(65)
                            : context.hp(70),

                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),

                    /// TITLE
                    Positioned(
                      top: context.hp(15),
                      left: context.wp(5),

                      child: Row(
                        children: [
                          SizedBox(width: context.wp(2.2)),

                          Text(
                            "Holiday Packages",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.isMobile ? 24 : 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// SEARCH / BANNER CARD
                    Positioned(
                      left: context.wp(4.7),
                      right: context.wp(4.7),
                      bottom: -context.hp(4),

                      child: const Material(
                        color: Colors.transparent,
                        child: HolidaysSearchCard(),
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 55)),
              SliverToBoxAdapter(
                child: BlocProvider<ExclusiveDealsBloc>(
                  create: (context) => sl<ExclusiveDealsBloc>(),
                  child: const TransportExclusiveDealsSection(),
                ),
              ),

              const SliverToBoxAdapter(child: TravelStoriesSection()),
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

              SliverToBoxAdapter(child: SizedBox(height: context.hp(5))),
            ],
          ),
        ),

        bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      ),
    );
  }
}
