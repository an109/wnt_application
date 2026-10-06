import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/custom_drawer.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../injection_container.dart';
import '../../../DiyHoliday/data/diy_dates.dart';
import '../../../DiyHoliday/data/diy_origins.dart';
import '../../../DiyHoliday/data/diy_search_query.dart';
import '../../../DiyHoliday/presentation/widgets/diy_book_now_section.dart';
import '../../../DiyHoliday/presentation/widgets/diy_compact_search_bar.dart';
import '../../../DiyHoliday/presentation/widgets/diy_holiday_search_card.dart';
import '../../../DiyHoliday/presentation/widgets/diy_theme_section.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../home/presentation/screen_sections/about_company_section.dart';
import '../../../home/presentation/screen_sections/service_info_section.dart';
import '../../../home/presentation/screens/deals.dart';
import '../../../travel_stories/presentation/screen/travel_stories.dart';

/// Entry point of the holiday flow.
///
/// Everything under the hero is driven by the DIY Holidays API
/// (diy.thewandernova.com): the search form, the Book Now destinations
/// (API 1) and the Holiday By Theme tiles (API 2). The surrounding
/// deals/stories/company sections are the app's shared ones and are
/// untouched.
class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  /// Seeds the Book Now / theme shortcuts with whatever the user last
  /// searched, so tapping one carries their own party size and date.
  DiySearchQuery _query = DiySearchQuery(
    origin: DiyOrigins.defaultOrigin,
    departureDate: DiyDates.defaultDeparture(),
  );

  final ScrollController _scroll = ScrollController();
  final GlobalKey<DiyHolidaySearchCardState> _formKey = GlobalKey();

  /// The form has scrolled out of sight — show the folded search bar.
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    DiySearchStore.loadLastSearch().then((saved) {
      if (saved != null && mounted) setState(() => _query = saved);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final compact = _scroll.offset > context.h(380);
    if (compact != _compact) setState(() => _compact = compact);
  }

  void _scrollToForm() => _scroll.animateTo(
    0,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    // White page (no hero photo), so the status bar icons go dark.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: context.scrollPhysics,
            slivers: [
              /// HERO + SEARCH FORM — full bleed, no padding, so the background
              /// image spans the screen and fades into the content below.
              SliverToBoxAdapter(child: DiyHolidaySearchCard(key: _formKey)),

              /// BOOK NOW — destinations from GET /destinations/
              SliverToBoxAdapter(child: SizedBox(height: context.h(10))),
              SliverToBoxAdapter(child: DiyBookNowSection(query: _query)),

              /// PROMO BANNERS (shared exclusive-deals carousel)
              SliverToBoxAdapter(child: SizedBox(height: context.h(20))),
              SliverToBoxAdapter(
                child: BlocProvider<ExclusiveDealsBloc>(
                  create: (context) => sl<ExclusiveDealsBloc>(),
                  child: const DealsSection(),
                ),
              ),

              /// HOLIDAY BY THEME — tiles from GET /themes/
              SliverToBoxAdapter(child: SizedBox(height: context.h(10))),
              SliverToBoxAdapter(child: DiyThemeSection(query: _query)),

              /// TRAVEL STORIES
              // SliverToBoxAdapter(child: SizedBox(height: context.h(20))),
              // const SliverToBoxAdapter(child: TravelStoriesSection()),

              /// ABOUT COMPANY
              // SliverToBoxAdapter(
              //   child: BlocProvider(
              //     create: (_) => sl<GeneralSettingsBloc>()
              //       ..add(const LoadGeneralSettings(domain: 'thewandernova.com')),
              //     child: const AboutCompanySection(),
              //   ),
              // ),
              //
              // /// SERVICES INFO
              // SliverToBoxAdapter(
              //   child: BlocProvider(
              //     create: (_) => sl<GeneralSettingsBloc>()
              //       ..add(const LoadGeneralSettings(domain: 'thewandernova.com')),
              //     child: const ServicesInfoSection(),
              //   ),
              // ),
              SliverToBoxAdapter(child: SizedBox(height: context.h(5))),
            ],
          ),
          // Figma `On scroll Holiday`: the form folded to one line.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _compact
                  ? DiyCompactSearchBar(
                      key: const ValueKey('compact'),
                      query: _formKey.currentState?.query ?? _query,
                      onBack: () => Navigator.of(context).maybePop(),
                      onTapSummary: _scrollToForm,
                      onSearch: () {
                        final form = _formKey.currentState;
                        if (form == null) {
                          _scrollToForm();
                          return;
                        }
                        form.search();
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      ),
    );
  }
}
