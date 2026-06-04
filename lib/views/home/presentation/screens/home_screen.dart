import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/custom_drawer.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../injection_container.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';
import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../../Hotel/screen/hotel_screen.dart';
import '../../../MMT_Holiday/screen/holiday_screen.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../Transport/screen/transport_screen.dart';
import '../../../footer/presentation/widget/footer_banner_widget.dart';
import '../../../travel_stories/presentation/screen/travel_stories.dart';
import '../../../visa/presentation/screen/visa_screen.dart';
import '../screen_sections/about_company_section.dart';
import '../screen_sections/faq/FAQ_section.dart';
import '../../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../../trending_route/presentation/screen/trending_routes.dart';
import '../screen_sections/service_info_section.dart';
import '../screen_sections/why_choose_us/why_choose_us.dart';
import '../../flight/flight_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _printInitialDimensions();
  }

  void _printInitialDimensions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      print('Initial Width: ${size.width}, Height: ${size.height}');
    });
  }

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
            padding: EdgeInsets.all(context.wp(2)),
            child: Image.asset(
              "assets/images/wander_nova_logo.jpg",
              height: context.hp(4.5),
              width: context.hp(4.5),
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

          // If PopularDestinations has a GlobalKey or you're using context
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
                  padding: EdgeInsets.symmetric(horizontal: context.wp(3.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //  BOLDER & LARGER TITLE
                      SizedBox(height: context.hp(2)),

                      // ================= HERO CARD =================
                      _buildHeroCard(
                        context,
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15),

                      SizedBox(height: context.hp(3)),

                      // Main Services (Top Row - 4 items)
                      _buildMainServicesGrid(context),

                      SizedBox(height: context.hp(0.7)),

                      //  BOLDER & LARGER SUBTITLE
                      Text(
                        'More Services',
                        style: TextStyle(
                          fontSize: context.titleLarge, // Use responsive font
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: context.letterSpacingTight,
                        ),
                      ),
                      SizedBox(height: context.hp(2)),

                      _buildAdditionalServicesGrid(context),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ===== EXISTING SECTIONS =====
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

              SliverToBoxAdapter(
                child: FooterBannerWidget(
                  domain: 'thewandernova.com',
                  height: context.hp(18),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: context.hp(5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.wp(5)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3C72), // Dark Blue
            Color(0xFF2A5298), // Medium Blue
            Color(0xFF7E8BA3), // Light Blue Grey
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Animated Background Elements
          Positioned(top: -20, right: -20, child: _buildAnimatedCloud(context)),
          Positioned(
            bottom: 40,
            left: -30,
            child: _buildAnimatedCloud(context, delay: 500),
          ),
          Positioned(top: 100, right: 50, child: _buildAnimatedPlane(context)),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Discover Your Next\nJourney ✈️",
                style: TextStyle(
                  fontSize: context.titleLarge * 1.3,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.hp(1.5)),
              Text(
                "Flights, hotels and more — all in one place.",
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.hp(1)),

              // Search Bar with Animation
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(50),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.2),
              //         blurRadius: 15,
              //         offset: const Offset(0, 5),
              //       ),
              //     ],
              //   ),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: TextField(
              //           decoration: InputDecoration(
              //             hintText: "Search destinations or deals",
              //             hintStyle: TextStyle(
              //               color: Colors.grey.shade400,
              //               fontSize: context.bodyMedium,
              //             ),
              //             border: InputBorder.none,
              //             contentPadding: EdgeInsets.symmetric(
              //               horizontal: context.wp(5),
              //               vertical: context.hp(2),
              //             ),
              //             prefixIcon: Icon(
              //               Icons.search_rounded,
              //               color: const Color(0xFF2A5298),
              //               size: context.iconMedium,
              //             ),
              //           ),
              //           style: TextStyle(
              //             fontSize: context.bodyMedium,
              //             color: Colors.black87,
              //           ),
              //         ),
              //       ),
              //       Container(
              //         margin: EdgeInsets.only(right: 4),
              //         decoration: const BoxDecoration(
              //           gradient: LinearGradient(
              //             colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              //           ),
              //           shape: BoxShape.circle,
              //           boxShadow: [
              //             BoxShadow(
              //               color: Color(0xFF1E3C72),
              //               blurRadius: 10,
              //               offset: Offset(0, 4),
              //             ),
              //           ],
              //         ),
              //         child: Material(
              //           color: Colors.transparent,
              //           child: InkWell(
              //             onTap: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (_) => const FlightScreen(),
              //                 ),
              //               );
              //             },
              //             borderRadius: BorderRadius.circular(50),
              //             child: Padding(
              //               padding: EdgeInsets.all(context.wp(2.5)),
              //               child: Icon(
              //                 Icons.arrow_forward_ios_rounded,
              //                 color: Colors.white,
              //                 size: context.iconSmall,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0),

              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(50),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          "Book now and save big",
                          speed: const Duration(milliseconds: 70),
                          textStyle: GoogleFonts.aBeeZee(
                            color: AppColors.lightBg,
                            fontSize: context.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    // SizedBox(width: context.wp(1)),
                    // const Icon(
                    //   Icons.arrow_forward_rounded,
                    //   color: Colors.white,
                    //   size: 18,
                    // ),
                  ],
                ),
              ),
              SizedBox(height: context.hp(1)),

              // Animated Destination Chips
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroActionItem(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onTap,
      ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.hp(0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: context.iconMedium,
              ),
              SizedBox(height: context.hp(0.5)),
              Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.bodySmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCloud(BuildContext context, {int delay = 0}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(-10 * (1 - value), 0),
          child: Opacity(
            opacity: value * 0.3,
            child: Icon(
              Icons.cloud_rounded,
              color: Colors.white,
              size: context.isMobile ? 60 : 80,
            ),
          ),
        );
      },
    );
  }


  Widget _buildAnimatedPlane(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -5 * sin(value * 3.14159 * 2)),
          child: Transform.rotate(
            angle: sin(value * 3.14159 * 2) * 0.1,
            child: Opacity(
              opacity: 0.4,
              child: Icon(
                Icons.flight_rounded,
                color: Colors.white,
                size: context.isMobile ? 40 : 50,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainServicesGrid(BuildContext context) {
    final services = [
      ServiceItem(
        assetIcon: 'assets/icons/flight.png',
        // icon: Icons.flight_takeoff,
        label: 'Flights',
        color: const Color(0xFF4A90E2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlightScreen()),
        ),
      ),
      ServiceItem(
        assetIcon: 'assets/icons/hotel.png',
        label: 'Hotels',
        color: const Color(0xFF50C878),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
      ServiceItem(
        // icon: Icons.assignment_turned_in,
        assetIcon: 'assets/icons/visa.png',
        label: 'Visa',
        color: const Color(0xFF8E44AD),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VisaScreen()),
        ),
      ),
      ServiceItem(
        // icon: Icons.beach_access,
        assetIcon: 'assets/icons/holiday.png',
        label: 'Holidays',
        color: const Color(0xFFFF6B6B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewHolidayScreen()),
          // MaterialPageRoute(builder: (_) => const HolidaysScreen()),
        ),
      ),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: context.isMobile
                ? 0.75
                : (context.isTablet ? 0.8 : 0.85),
            crossAxisSpacing: context.wp(1.5),
            mainAxisSpacing: context.hp(1),
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            // Use the MAIN service icon builder with larger Google Fonts text
            return _buildMainServiceIcon(context, services[index]);
          },
        ),
        SizedBox(height: context.hp(1.5)),
      ],
    );
  }

  Widget _buildMainServiceIcon(BuildContext context, ServiceItem service) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -2 * value),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: service.onTap,
              borderRadius: BorderRadius.circular(context.isMobile ? 16 : 18),
              splashColor: service.color.withOpacity(0.15),
              highlightColor: service.color.withOpacity(0.08),
              child: Container(
                // Changed from AnimatedContainer to Container
                padding: EdgeInsets.symmetric(
                  vertical: context.hp(2.2),
                  horizontal: context.gapSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    context.isMobile ? 16 : 18,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                  mainAxisSize: MainAxisSize.min, // Use min instead of max
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 3,
                          top: 3,
                          child: Icon(
                            service.icon,
                            color: service.color.withOpacity(0.2),
                            size: context.iconXLarge,
                          ),
                        ),
                        Positioned(
                          left: 1,
                          top: 2,
                          child: Icon(
                            service.icon,
                            color: service.color.withOpacity(0.15),
                            size: context.iconXLarge,
                          ),
                        ),
                        service.assetIcon != null
                            ? Image.asset(
                                service.assetIcon!,
                                height: context.iconXLarge + 14,
                                width: context.iconXLarge + 14,
                                fit: BoxFit.contain,
                              )
                            : ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    service.iconColor,
                                    service.iconColor.withOpacity(0.7),
                                  ],
                                ).createShader(bounds),
                                child: Icon(
                                  service.icon,
                                  color: Colors.white,
                                  size: context.iconXLarge,
                                ),
                              ),
                        Positioned(
                          left: -2,
                          top: -2,
                          child: Icon(
                            service.icon,
                            color: Colors.white.withOpacity(0.15),
                            size: context.iconXLarge - 2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.gapSmall),
                    // REMOVED Expanded widget from here
                    Text(
                      service.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoFlex(
                        fontSize: context.titleSmall,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.2,
                        letterSpacing: -0.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== ADDITIONAL SERVICES GRID =====
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
        icon: Icons.emoji_events_outlined,
        label: 'Tours & Attractions',
        color: const Color(0xFF1E3C72),
        badge: 'NEW',
        onTap: () => _showComingSoon(context, 'Tours & Attractions'),
      ),
      ServiceItem(
        icon: Icons.access_time_outlined,
        label: 'Hourly Stays',
        color: const Color(0xFF1E3C72),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: context.isMobile
            ? 0.85
            : (context.isTablet ? 0.9 : 1.0),
        crossAxisSpacing: context.wp(2),
        mainAxisSpacing: context.hp(2),
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceIcon(context, services[index]);
      },
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
              scale: 1 - (value * 0.02), // Subtle scale on animation
              child: Transform.translate(
                offset: Offset(0, -2 * value),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Add haptic feedback (optional)
                      // HapticFeedback.lightImpact();
                      service.onTap();
                    },
                    onTapDown: (_) {
                      setState(() {});
                    },
                    onTapUp: (_) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        setState(() {});
                      });
                    },
                    borderRadius: BorderRadius.circular(
                      context.isMobile ? 16 : 18,
                    ),
                    splashColor: service.color.withOpacity(0.15),
                    highlightColor: service.color.withOpacity(0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.all(context.gapSmall),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.isMobile ? 16 : 18,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
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
                                left: 3,
                                top: 4,
                                child: Icon(
                                  service.icon,
                                  color: service.color.withOpacity(0.2),
                                  size: context.iconXLarge,
                                ),
                              ),
                              Positioned(
                                left: 1,
                                top: 2,
                                child: Icon(
                                  service.icon,
                                  color: service.color.withOpacity(0.15),
                                  size: context.iconXLarge,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    service.color,
                                    service.color.withOpacity(0.7),
                                  ],
                                ).createShader(bounds),
                                child: Icon(
                                  service.icon,
                                  color: Colors.white,
                                  size: context.iconXLarge,
                                ),
                              ),
                              Positioned(
                                left: -2,
                                top: -2,
                                child: Icon(
                                  service.icon,
                                  color: Colors.white.withOpacity(0.15),
                                  size: context.iconXLarge - 2,
                                ),
                              ),
                              if (service.badge != null)
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    builder: (context, double scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFE74C3C),
                                                Color(0xFFC0392B),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
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
                          SizedBox(height: context.gapXSmall),
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
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon!')));
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

  Color get iconColor => color ?? Colors.blue;

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
