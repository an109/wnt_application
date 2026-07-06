import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/custom_drawer.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/views/T_location/presentation/screen/booking_card.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../injection_container.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';
import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../../Holidays/presentation/widget/holiday_search_card.dart';
import '../../../Hotel/screen/hotel_screen.dart';
import '../../../Hotel/section/exclusive_deals/hotel_search_card.dart';
import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../Transport/screen/transport_screen.dart';
import '../../../airport/presentation/screen/search_card.dart';
import '../../../travel_stories/presentation/screen/travel_stories.dart';
import '../../../visa/presentation/screen/visa_screen.dart';
import '../../../visa/presentation/sections/visa_banner_section.dart';
import '../screen_sections/about_company_section.dart';
import '../screen_sections/contact_section.dart';
import '../screen_sections/faq/FAQ_section.dart';
import '../../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../../trending_route/presentation/screen/trending_routes.dart';
import '../screen_sections/service_info_section.dart';
import '../screen_sections/why_choose_us/why_choose_us.dart';
import '../../flight/flight_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedServiceIndex = 0;
  bool isOneWay = true;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

  List<Map<String, dynamic>> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _printInitialDimensions();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefsManager =
      await PreferencesManager.create(await SharedPreferences.getInstance());
      final history = prefsManager.getSearchHistory();

      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final item in history) {
        final type = (item['type'] ?? 'flight').toString();
        String key;
        if (type == 'hotel') {
          final destId = (item['destination']?['id'] ?? '').toString();
          if (destId.isEmpty) continue;
          key = 'hotel-$destId';
        } else if (type == 'transport') {
          final pickupId = (item['pickup']?['id'] ?? '').toString();
          final dropoffId = (item['dropoff']?['id'] ?? '').toString();
          if (pickupId.isEmpty || dropoffId.isEmpty) continue;
          key = 'transport-$pickupId-$dropoffId';
        } else {
          final fromCode = (item['fromAirport']?['code'] ?? '').toString();
          final toCode = (item['toAirport']?['code'] ?? '').toString();
          if (fromCode.isEmpty || toCode.isEmpty) continue;
          key = 'flight-$fromCode-$toCode';
        }
        if (seen.add(key)) unique.add(item);
        if (unique.length >= 5) break;
      }

      if (mounted) setState(() => _recentSearches = unique);
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  String _formatSearchDate(dynamic iso) {
    if (iso == null) return '';
    try {
      return DateFormat('dd MMM').format(DateTime.parse(iso.toString()));
    } catch (_) {
      return '';
    }
  }

  void _printInitialDimensions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      print('Initial Width: ${size.width}, Height: ${size.height}');
    });
  }

  final List<HomeServiceTab> serviceTabs = [
    HomeServiceTab(
      title: "Flights",
      icon: Icons.flight_takeoff_rounded,
    ),
    HomeServiceTab(
      title: "Hotels",
      icon: Icons.hotel_rounded,
    ),
    HomeServiceTab(
      title: "Holidays",
      icon: Icons.beach_access_rounded,
    ),
    HomeServiceTab(
      title: "Visa",
      icon: Icons.article_outlined,
    ),
    HomeServiceTab(
      title: "Cabs",
      icon: Icons.local_taxi_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    print(' Screen Updated - Width: ${size.width}, Height: ${size.height}');

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: WanderNovaLogo(
          scaleFactor: context.isMobile ? 0.6 : (context.isTablet ? 0.8 : 1.0),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: context.h(36),
              width: context.h(36),
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final generalBloc = context.read<GeneralSettingsBloc>();
          final dealsBloc = context.read<ExclusiveDealsBloc>();

          generalBloc.add(const LoadFaqList(domain: 'thewandernova.com'));
          generalBloc.add(
            const LoadGeneralSettings(domain: 'thewandernova.com'),
          );
          dealsBloc.add(const LoadExclusiveDeals());
          _loadRecentSearches();

          await Future.wait([
            Future.delayed(const Duration(milliseconds: 500)),
          ]);
        },
        color: const Color(0xff005B7F),
        backgroundColor: Colors.white,
        child: Container(
          color: const Color(0xFFF8F9FA),
          child: CustomScrollView(
            physics: context.scrollPhysics,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(context).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15),
                      SizedBox(height: context.h(6)),
                      // Text(
                      //   'More Services',
                      //   style: TextStyle(
                      //     fontSize: context.titleLarge,
                      //     fontWeight: FontWeight.w800,
                      //     color: Colors.black87,
                      //     letterSpacing: context.letterSpacingTight,
                      //   ),
                      // ),
                      // SizedBox(height: context.h(16)),
                      // _buildAdditionalServicesGrid(context),
                      SizedBox(height: context.h(20)),
                      _buildRecentSearchesSection(context),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: BlocProvider<ExclusiveDealsBloc>(
                  create: (context) => sl<ExclusiveDealsBloc>(),
                  child: const TransportExclusiveDealsSection(),
                ),
              ),
              const SliverToBoxAdapter(child: PopularDestinations()),
              const SliverToBoxAdapter(child: TrendingPackages()),
              const SliverToBoxAdapter(child: TravelStoriesSection()),
              SliverToBoxAdapter(
                child: BlocProvider(
                  create: (_) =>
                  sl<GeneralSettingsBloc>()
                    ..add(const LoadFaqList(domain: 'thewandernova.com')),
                  child: const FAQSection(),
                ),
              ),
              const SliverToBoxAdapter(child: WhyChooseUs()),
              SliverToBoxAdapter(
                child: BlocProvider(
                  create: (_) => sl<GeneralSettingsBloc>()
                    ..add(
                      const LoadGeneralSettings(domain: 'thewandernova.com'),
                    ),
                  child: const AboutCompanySection(),
                ),
              ),
              SliverToBoxAdapter(
                child: BlocProvider(
                  create: (_) => sl<GeneralSettingsBloc>()
                    ..add(
                      const LoadGeneralSettings(domain: 'thewandernova.com'),
                    ),
                  child: const ServicesInfoSection(),
                ),
              ),
              const SliverToBoxAdapter(child: ContactSection()),
              SliverToBoxAdapter(child: SizedBox(height: context.h(40))), // 40px on design
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    // Load the app/dashboard banner via its own GeneralSettingsBloc instance
    // (mirrors the other sections that each own a bloc), then paint it behind
    // the hero content. Falls back to the brand gradient while loading / on
    // error so the UI never looks broken.
    return BlocProvider<GeneralSettingsBloc>(
      create: (_) => sl<GeneralSettingsBloc>()
        ..add(const LoadGeneralSettings(domain: 'thewandernova.com')),
      child: BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
        buildWhen: (previous, current) =>
            current is GeneralSettingsLoaded ||
            current is PopularDestinationsDataLoaded,
        builder: (context, state) {
          String? bannerUrl;
          if (state is GeneralSettingsLoaded) {
            bannerUrl = _heroBannerUrl(state.generalSettings);
          } else if (state is PopularDestinationsDataLoaded) {
            bannerUrl = _heroBannerUrl(state.generalSettings);
          }
          return _buildHeroCardContent(context, bannerUrl);
        },
      ),
    );
  }

  /// Picks the best available remote image for the hero background.
  String? _heroBannerUrl(GeneralSettingsEntity settings) {
    for (final url in [settings.dashboardImage, settings.dashboardImage]) {
      if (url.trim().isNotEmpty) return url.trim();
    }
    return null;
  }

  Widget _buildHeroCardContent(BuildContext context, String? bannerUrl) {
    final borderRadius = BorderRadius.circular(context.r(8));
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.25),
            blurRadius: context.w(20),
            offset: Offset(0, context.h(8)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Background fills the area sized by the content column below.
            Positioned.fill(child: _buildHeroBackground(context, bannerUrl)),
            Padding(
              padding: EdgeInsets.all(context.w(10)), // 12px on design
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.h(8)), // 8px on design
                  Text(
                    "Discover Your Next\nJourney",
                    // "Discover Your Next\nJourney ✈",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.titleLarge * 1.2,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  Text(
                    "Flights, Hotels and more — all in one place.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(.9),
                      fontSize: context.bodyMedium,
                    ),
                  ),
                  SizedBox(height: context.h(16)),
                  _buildServiceTabs(context),
                  SizedBox(height: context.h(8)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildSelectedCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Brand-gradient background that, when a [bannerUrl] is available, shows the
  /// remote image on top with a dark scrim for text legibility.
  Widget _buildHeroBackground(BuildContext context, String? bannerUrl) {
    const brandGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF003B95),
        Color(0xFF005B7F),
      ],
    );

    if (bannerUrl == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(gradient: brandGradient),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Shown while the image loads or if it fails to load.
        const DecoratedBox(
          decoration: BoxDecoration(gradient: brandGradient),
        ),
        Image.network(
          bannerUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : const SizedBox.shrink(),
        ),
        // Dark scrim keeps the white headline and tabs readable on any image.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.45),
                Colors.black.withOpacity(0.20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTabs(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(6)), // 6px on design
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(context.r(18)), // 18px on design
      ),
      child: Row(
        children: List.generate(
          serviceTabs.length,
              (index) {
            final selected = selectedServiceIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedServiceIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.symmetric(vertical: context.h(8)), // 8px on design
                  decoration: BoxDecoration(
                    color: selected ? Colors.transparent : Colors.transparent,
                    borderRadius: BorderRadius.circular(context.r(14)), // 14px on design
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        serviceTabs[index].icon,
                        color: selected ?  const Color(0xFF003B95) : Colors.white,
                        size: context.iconMedium,
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        serviceTabs[index].title,
                        style: TextStyle(
                          color: selected ? const Color(0xFF003B95) : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: context.fs(11), // 11px on design
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedCard() {
    switch (selectedServiceIndex) {
      case 0:
        return const SearchCard(key: ValueKey("flight"));
      case 1:
        return const HotelSearchCard(key: ValueKey("hotel"));
      case 2:
        return const HolidaysSearchCard(key: ValueKey("holiday"));
      case 3:
        return const VisaBannerSection(key: ValueKey("visa"));
      case 4:
        return TransportBookingCard(
          key: const ValueKey("cab"),
          isOneWay: isOneWay,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          onTripTypeChanged: (value) {
            setState(() => isOneWay = value);
          },
          onDateChanged: (date) {
            setState(() => selectedDate = date);
          },
          onTimeChanged: (time) {
            setState(() => selectedTime = time);
          },
        );
      default:
        return const SearchCard(key: ValueKey("default"));
    }
  }

  Widget _buildAdditionalServicesGrid(BuildContext context) {
    final services = [
      ServiceItem(
        icon: Icons.local_taxi_outlined,
        label: 'Airport Cabs',
        color: const Color(0xFF1E3C72),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransportBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.home_work_outlined,
        label: 'Villas & Homestays',
        color: const Color(0xFF1E3C72),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.my_library_books_outlined,
        label: 'Visa',
        color: const Color(0xFF1E3C72),
        badge: 'new',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisaScreen())),
      ),
      ServiceItem(
        icon: Icons.flight_outlined,
        label: 'Flights',
        color: const Color(0xFF1E3C72),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlightScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: context.isMobile ? 0.85 : (context.isTablet ? 0.9 : 1.0),
        crossAxisSpacing: context.w(8),
        mainAxisSpacing: context.h(16),
      ),
      itemCount: services.length,
      itemBuilder: (context, index) => _buildServiceIcon(context, services[index]),
    );
  }

  Widget _buildServiceIcon(BuildContext context, ServiceItem service) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 1 - (value * 0.02),
              child: Transform.translate(
                offset: Offset(0, -2 * value),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: service.onTap,
                    onTapDown: (_) => setState(() {}),
                    onTapUp: (_) {
                      Future.delayed(const Duration(milliseconds: 100), () => setState(() {}));
                    },
                    borderRadius: BorderRadius.circular(context.isMobile ? context.r(16) : context.r(18)),
                    splashColor: service.color.withOpacity(0.15),
                    highlightColor: service.color.withOpacity(0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.all(context.w(8)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.isMobile ? context.r(16) : context.r(18)),
                        boxShadow: [
                          // BoxShadow(
                          //   color: Colors.black.withOpacity(0.1),
                          //   blurRadius: context.w(12), // 12px on design
                          //   offset: Offset(0, context.h(6)), // 6px on design
                          // ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: context.w(4),
                            offset: Offset(0, context.h(2)),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.12),
                          width: 1.2,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.shade50.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: context.w(3),
                                top: context.h(4),
                                child: Icon(
                                  service.icon,
                                  color: service.color.withOpacity(0.2),
                                  size: context.iconLarge,
                                ),
                              ),
                              Positioned(
                                left: context.w(1),
                                top: context.h(2),
                                child: Icon(
                                  service.icon,
                                  color: service.color.withOpacity(0.15),
                                  size: context.iconLarge,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [service.color, service.color.withOpacity(0.7)],
                                ).createShader(bounds),
                                child: Icon(
                                  service.icon,
                                  color: Colors.white,
                                  size: context.iconLarge,
                                ),
                              ),
                              Positioned(
                                left: -context.w(2),
                                top: -context.h(2),
                                child: Icon(
                                  service.icon,
                                  color: Colors.white.withOpacity(0.15),
                                  size: context.iconXLarge - 2,
                                ),
                              ),
                              if (service.badge != null)
                                Positioned(
                                  right: -context.w(33),
                                  top: -context.h(26),
                                  child: TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    builder: (context, double scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.w(5),
                                            vertical: context.h(3),
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(context.r(10)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.4),
                                                blurRadius: context.w(6),
                                                offset: Offset(0, context.h(2)),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            service.badge!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: context.caption,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: context.h(6)), // 6px on design
                          Flexible(
                            child: Text(
                              service.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: context.labelMedium,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.3,
                                letterSpacing: context.letterSpacingTight,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: context.w(2),
                                    offset: Offset(0, context.h(1)),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSearchCard(BuildContext context, Map<String, dynamic> search) {
    final type = (search['type'] ?? 'flight').toString();

    String typeLabel;
    String primaryLine;
    String secondaryLine;
    String date;

    if (type == 'hotel') {
      typeLabel = 'Hotel';
      final dest = search['destination'];
      primaryLine = (dest?['name'] ?? '').toString();
      final checkIn = _formatSearchDate(search['checkInDate']);
      final checkOut = _formatSearchDate(search['checkOutDate']);
      secondaryLine = checkIn.isNotEmpty ? '$checkIn → $checkOut' : '';
      date = checkIn;
    } else if (type == 'transport') {
      typeLabel = 'Cab';
      final pickup = search['pickup'];
      final dropoff = search['dropoff'];
      final pickupName = (pickup?['city'] ?? pickup?['label'] ?? pickup?['name'] ?? '').toString();
      final dropoffName = (dropoff?['city'] ?? dropoff?['label'] ?? dropoff?['name'] ?? '').toString();
      primaryLine = pickupName;
      secondaryLine = dropoffName;
      date = _formatSearchDate(search['pickupDate']);
    } else {
      typeLabel = 'Flight';
      final from = search['fromAirport'];
      final to = search['toAirport'];
      final fromCity = (from?['city'] ?? '').toString();
      final toCity = (to?['city'] ?? '').toString();
      primaryLine = '${(from?['code'] ?? '').toString()}  →  ${(to?['code'] ?? '').toString()}';
      secondaryLine = '$fromCity → $toCity';
      date = _formatSearchDate(search['departureDate']);
    }

    return Container(
      width: context.w(240),
      margin: EdgeInsets.only(right: context.w(12)),
      padding: EdgeInsets.all(context.w(15)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                typeLabel,
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: TextStyle(
                  fontSize: context.labelMedium,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Text(
            primaryLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.titleMedium,
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            secondaryLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: context.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesSection(BuildContext context) {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Searches",
          style: TextStyle(
            fontSize: context.titleLarge,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: context.h(12)), // 12px on design
        SizedBox(
          height: context.h(105),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) =>
                _buildRecentSearchCard(context, _recentSearches[index]),
          ),
        ),
      ],
    );
  }
}

class ServiceItem {
  final IconData? icon;
  final String? assetIcon;
  final String label;
  final Color color;
  final Color? backgroundColor;
  final String? badge;
  final VoidCallback onTap;

  Color get iconColor => color;

  ServiceItem({
    this.icon,
    this.assetIcon,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.badge,
    required this.onTap,
  });
}

class HomeServiceTab {
  final String title;
  final IconData icon;

  HomeServiceTab({
    required this.title,
    required this.icon,
  });
}
