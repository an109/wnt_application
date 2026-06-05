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
            padding: EdgeInsets.all(context.w(8)), // 8px on design
            child: Image.asset(
              "assets/images/wander_nova_logo.png",
              height: context.h(36), // 36px on design
              width: context.h(36),  // 36px on design
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
                  padding: EdgeInsets.symmetric(horizontal: context.w(14)), // 14px on design
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.h(16)), // 16px on design

                      // ================= HERO CARD =================
                      _buildHeroCard(context).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15),

                      SizedBox(height: context.h(24)), // 24px on design

                      // Main Services (Top Row - 4 items)
                      _buildMainServicesGrid(context),

                      SizedBox(height: context.h(6)), // 6px on design

                      Text(
                        'More Services',
                        style: TextStyle(
                          fontSize: context.titleLarge,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: context.letterSpacingTight,
                        ),
                      ),
                      SizedBox(height: context.h(16)), // 16px on design

                      _buildAdditionalServicesGrid(context),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: context.h(20))), // 20px on design

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
                  height: context.h(144), // 144px on design (18% of 800)
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: context.h(40))), // 40px on design
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(20)), // 20px on design
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3C72),
            Color(0xFF2A5298),
            Color(0xFF7E8BA3),
          ],
        ),
        borderRadius: BorderRadius.circular(context.r(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withOpacity(0.4),
            blurRadius: context.h(20),
            offset: Offset(0, context.h(10)),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
                  fontSize: context.fs(31), // 24 * 1.3 = 31.2
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: context.h(10),
                      offset: Offset(0, context.h(2)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(12)), // 12px on design
              Text(
                "Flights, hotels and more — all in one place.",
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: context.h(5),
                      offset: Offset(0, context.h(1)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(8)), // 8px on design

              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(context.r(50)),
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
                  ],
                ),
              ),
              SizedBox(height: context.h(8)), // 8px on design
            ],
          ),
        ],
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
              size: context.isMobile ? context.w(60) : context.w(80),
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
                size: context.isMobile ? context.w(40) : context.w(50),
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
        assetIcon: 'assets/icons/visa.png',
        label: 'Visa',
        color: const Color(0xFF8E44AD),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VisaScreen()),
        ),
      ),
      ServiceItem(
        assetIcon: 'assets/icons/holiday.png',
        label: 'Holidays',
        color: const Color(0xFFFF6B6B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewHolidayScreen()),
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
            crossAxisSpacing: context.w(6), // 6px on design
            mainAxisSpacing: context.h(8),  // 8px on design
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return _buildMainServiceIcon(context, services[index]);
          },
        ),
        SizedBox(height: context.h(12)), // 12px on design
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
              borderRadius: BorderRadius.circular(context.isMobile ? context.r(16) : context.r(18)),
              splashColor: service.color.withOpacity(0.15),
              highlightColor: service.color.withOpacity(0.08),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: context.h(18), // 18px on design
                  horizontal: context.gapSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.isMobile ? context.r(16) : context.r(18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: context.h(14),
                      offset: Offset(0, context.h(6)),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: context.h(4),
                      offset: Offset(0, context.h(2)),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.12),
                    width: context.w(1.2),
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
                          top: context.h(3),
                          child: Icon(
                            service.icon,
                            color: service.color.withOpacity(0.2),
                            size: context.iconXLarge,
                          ),
                        ),
                        Positioned(
                          left: context.w(1),
                          top: context.h(2),
                          child: Icon(
                            service.icon,
                            color: service.color.withOpacity(0.15),
                            size: context.iconXLarge,
                          ),
                        ),
                        service.assetIcon != null
                            ? Image.asset(
                          service.assetIcon!,
                          height: context.iconXLarge + context.w(14),
                          width: context.iconXLarge + context.w(14),
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
                          left: context.w(-2),
                          top: context.h(-2),
                          child: Icon(
                            service.icon,
                            color: Colors.white.withOpacity(0.15),
                            size: context.iconXLarge - context.w(2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.gapSmall),
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
        crossAxisSpacing: context.w(8), // 8px on design
        mainAxisSpacing: context.h(16),  // 16px on design
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
              scale: 1 - (value * 0.02),
              child: Transform.translate(
                offset: Offset(0, -2 * value),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
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
                    borderRadius: BorderRadius.circular(context.isMobile ? context.r(16) : context.r(18)),
                    splashColor: service.color.withOpacity(0.15),
                    highlightColor: service.color.withOpacity(0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.all(context.gapSmall),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.isMobile ? context.r(16) : context.r(18)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: context.h(12),
                            offset: Offset(0, context.h(6)),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: context.h(4),
                            offset: Offset(0, context.h(2)),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.12),
                          width: context.w(1.2),
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
                                  size: context.iconXLarge,
                                ),
                              ),
                              Positioned(
                                left: context.w(1),
                                top: context.h(2),
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
                                left: context.w(-2),
                                top: context.h(-2),
                                child: Icon(
                                  service.icon,
                                  color: Colors.white.withOpacity(0.15),
                                  size: context.iconXLarge - context.w(2),
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
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.w(6),
                                            vertical: context.h(3),
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
                                            borderRadius: BorderRadius.circular(context.r(10)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.4),
                                                blurRadius: context.h(6),
                                                offset: Offset(0, context.h(2)),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.5),
                                              width: context.w(1.5),
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
                                    blurRadius: context.h(2),
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
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
