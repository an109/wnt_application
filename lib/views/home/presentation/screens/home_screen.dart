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
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final generalBloc = context.read<GeneralSettingsBloc>();
          final dealsBloc = context.read<ExclusiveDealsBloc>();

          generalBloc.add(const LoadFaqList(domain: 'thewandernova.com'));
          generalBloc.add(const LoadGeneralSettings(domain: 'thewandernova.com'));
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
      // bottomNavigationBar: const NewBottomNav(currentIndex: 0),
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
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),

        borderRadius: BorderRadius.circular(26),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Discover Your Next Journey ✈",
            style: TextStyle(
              fontSize: context.titleLarge,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: context.hp(1)),

          Text(
            "Flights, hotels, holidays and more in one place.",
            style: TextStyle(
              fontSize: context.bodyMedium,
              color: Colors.white.withOpacity(0.75),
              height: 1.4,
            ),
          ),

          SizedBox(height: context.hp(2.2)),

          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FlightScreen()));
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(1.5),
              ),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),

              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withOpacity(0.7),
                  ),

                  SizedBox(width: context.wp(2.5)),

                  Expanded(
                    child: Text(
                      "Search destinations...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(8),

                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),

                    child:  Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainServicesGrid(BuildContext context) {
    final services = [
      ServiceItem(
        icon: Icons.flight_takeoff,
        label: 'Flights',
        color: const Color(0xFF4A90E2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlightScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.hotel,
        label: 'Hotels',
        color: const Color(0xFF50C878),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.assignment_turned_in,
        label: 'Visa',
        color: const Color(0xFF8E44AD),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VisaScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.beach_access,
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
            childAspectRatio: context.isMobile ? 0.75 : (context.isTablet ? 0.8 : 0.85),
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
              child: Container(  // Changed from AnimatedContainer to Container
                padding: EdgeInsets.symmetric(
                  vertical: context.hp(2.2),
                  horizontal: context.gapSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.isMobile ? 16 : 18),
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
                  mainAxisSize: MainAxisSize.min,  // Use min instead of max
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
        icon: Icons.directions_bus,
        label: 'Transport',
        color: const Color(0xFFFFA500),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransportBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.local_taxi,
        label: 'Airport Cabs',
        color: const Color(0xFF9B59B6),
        onTap: () => _showComingSoon(context, 'Airport Cabs'),
      ),
      ServiceItem(
        icon: Icons.home_work,
        label: 'Villas & Homestays',
        color: const Color(0xFF1ABC9C),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.directions_car,
        label: 'Outstation Cabs',
        color: const Color(0xFFE74C3C),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransportBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.attach_money,
        label: 'Forex Card',
        color: const Color(0xFF34495E),
        onTap: () => _showComingSoon(context, 'Forex Card'),
      ),
      ServiceItem(
        icon: Icons.emoji_events,
        label: 'Tours & Attractions',
        color: const Color(0xFFF39C12),
        badge: 'NEW',
        onTap: () => _showComingSoon(context, 'Tours & Attractions'),
      ),
      ServiceItem(
        icon: Icons.access_time,
        label: 'Hourly Stays',
        color: const Color(0xFF16A085),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        ),
      ),
      ServiceItem(
        icon: Icons.shield_outlined,
        label: 'Travel Insurance',
        color: const Color(0xFF27AE60),
        onTap: () => _showComingSoon(context, 'Travel Insurance'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: context.isMobile ? 0.85 : (context.isTablet ? 0.9 : 1.0),
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
                    borderRadius: BorderRadius.circular(context.isMobile ? 16 : 18),
                    splashColor: service.color.withOpacity(0.15),
                    highlightColor: service.color.withOpacity(0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.all(context.gapSmall),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.isMobile ? 16 : 18),
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
                                              colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
}

// ===== SERVICE ITEM MODEL =====
class ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  ServiceItem({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
    required this.onTap,
  });
}