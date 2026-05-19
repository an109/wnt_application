import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/custom_drawer.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../common_widgets/new_bottom_nav.dart';
import '../../../../injection_container.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../../Holidays/presentation/screen/holidays_screen.dart';
import '../../../Hotel/screen/hotel_screen.dart';
import '../../../Transport/screen/transport_screen.dart';
import '../../../travel_stories/presentation/screen/travel_stories.dart';
import '../../../visa/presentation/screen/visa_screen.dart';
import '../screen_sections/faq/FAQ_section.dart';
import '../../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../../trending_route/presentation/screen/trending_routes.dart';
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
      body: Container(

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

                    SizedBox(height: context.hp(2.5)), // More spacing

                    // Main Services (Top Row - 4 items)
                    _buildMainServicesGrid(context),

                    SizedBox(height: context.hp(3)),

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
            const SliverToBoxAdapter(child: FAQSection()),
            const SliverToBoxAdapter(child: TravelStoriesSection()),
            const SliverToBoxAdapter(child: WhyChooseUs()),

            SliverToBoxAdapter(child: SizedBox(height: context.hp(5))),
          ],
        ),
      ),
      bottomNavigationBar: const NewBottomNav(currentIndex: 0),
    );
  }

  // ===== MAIN SERVICES GRID (4 columns - MakeMyTrip style) =====
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
        icon: Icons.assignment_turned_in, // Visa icon
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
          MaterialPageRoute(builder: (_) => const HolidaysScreen()),
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
        crossAxisSpacing: context.wp(3),
        mainAxisSpacing: context.hp(2),
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceIcon(context, services[index]);
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: service.onTap,
        borderRadius: BorderRadius.circular(context.isMobile ? 10 : 12),
        splashColor: service.color.withOpacity(0.1),
        highlightColor: service.color.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.all(context.gapSmall),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ 3D-STYLE ICON (No background, with shadow)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Shadow layer for 3D effect
                  Positioned(
                    left: 2,
                    top: 3,
                    child: Icon(
                      service.icon,
                      color: service.color.withOpacity(0.3),
                      size: context.iconXLarge,
                    ),
                  ),
                  // Main icon
                  Icon(
                    service.icon,
                    color: service.color,
                    size: context.iconXLarge,
                  ),

                  // Badge
                  if (service.badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          service.badge!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.caption,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: context.gapXSmall),

              // BOLDER & LARGER LABEL
              Flexible(
                child: Text(
                  service.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.labelMedium, // Use responsive font
                    fontWeight: FontWeight.w700, // Extra bold
                    color: Colors.black87,
                    height: 1.3,
                    letterSpacing: context.letterSpacingTight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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