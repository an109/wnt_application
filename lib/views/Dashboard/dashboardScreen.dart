import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/Dashboard/profile/screen/Profile_screen.dart';
import 'package:wander_nova/views/Dashboard/screen/make_payment.dart';
import 'package:wander_nova/views/Dashboard/screen/support_screen.dart';
import 'package:wander_nova/views/UpcomingTrips/presentation/screen/upcoming_trip.dart';
import 'package:wander_nova/views/wallet/wallet/screen/wallet_screen.dart';

import '../MyBookings/presentation/screen/MyBooking_Screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  final String userName;

  const DashboardScreen({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // =========================================
  // SIMPLE NAVIGATION METHOD
  // =========================================
  void _navigateToFeature(String feature) {

    // UPCOMING TRIPS
    if (feature == 'Upcoming Trips') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UpcomingTripsScreen(),
        ),
      );
    }

    // PROFILE SCREEN
    else if (feature == 'My Profile') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(

          ),
        ),
      );
    }
    // My Booking SCREEN
    else if (feature == 'My Booking') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyBookingScreen(),
        ),
      );
    }
    // Wallet SCREEN
    else if (feature == 'Wallet Balance') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletScreen(),
        ),
      );
    }
  // MAKE PAYMENT SCREEN
    else if (feature == 'Make Payment') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MakePaymentScreen(

          ),
        ),
      );
    }

    // SUPPORT SCREEN
    else if (feature == 'Support') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportScreen(),
        ),
      );
    }

    // OTHER FEATURES
    else {
      _showComingSoon(context, feature);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.isDesktop
              ? 80
              : context.isTablet
              ? 40
              : 16,
          vertical: context.isMobile ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: context.gapMedium),

            if (context.isDesktop || context.isTablet)
              _buildDesktopLayout(context)
            else
              _buildMobileLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: context.isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View your recent orders and manage\nyour bookings',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Profile Avatar
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0054A0),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: context.isMobile ? 20 : 24,
            backgroundColor:
            const Color(0xFF0054A0).withOpacity(0.1),
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : 'Hii',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0054A0),
                fontSize: context.isMobile ? 16 : 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildUpcomingTripsCard(context),
            ],
          ),
        ),

        SizedBox(width: context.gapLarge),

        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMenuGrid(context),
              SizedBox(height: context.gapMedium),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickSearch(context),
                  ),
                  SizedBox(width: context.gapMedium),
                  Expanded(
                    child: _buildWalletCard(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: context.gapMedium),

        _buildMenuGrid(context),
        SizedBox(height: context.gapMedium),


        _buildQuickSearch(context),
        SizedBox(height: context.gapMedium),

        _buildWalletCard(context),
        SizedBox(height: context.gapMedium),

        _buildUpcomingTripsCard(context),
      ],
    );
  }


  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.flight_takeoff,
        'title': 'Upcoming Trips',
        'color': const Color(0xFFFF9800),
      },
      {
        'icon': Icons.book_online,
        'title': 'My Bookings',
        'color': const Color(0xFF9C27B0),
      },
      {
        'icon': Icons.cancel,
        'title': 'View Cancellations',
        'color': const Color(0xFF2196F3),
      },
      {
        'icon': Icons.payment,
        'title': 'Make Payment',
        'color': const Color(0xFF009688),
      },
      {
        'icon': Icons.person,
        'title': 'My Profile',
        'color': const Color(0xFFFFC107),
      },
      {
        'icon': Icons.account_balance_wallet,
        'title': 'Wallet Balance',
        'color': const Color(0xFF4CAF50),
      },
      {
        'icon': Icons.people,
        'title': 'Travellers',
        'color': const Color(0xFFF44336),
      },
      {
        'icon': Icons.support_agent,
        'title': 'Support',
        'color': const Color(0xFFE91E63),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.isMobile ? 3 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return _buildCompactMenuCard(
            context,
            menuItems[index]['icon'] as IconData,
            menuItems[index]['title'] as String,
            menuItems[index]['color'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildCompactMenuCard(
      BuildContext context,
      IconData icon,
      String title,
      Color color,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToFeature(title),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSearch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Search',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tag,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          'AT - Enter reference number',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Get Itinerary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WALLET',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.green,
                  size: 18,
                ),
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'Available Balance Points: 0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTripsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flight_takeoff,
              size: 48,
              color: Colors.grey.shade300,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'No Upcoming Trips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'When you book a trip, you will see your itinerary here.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(
      BuildContext context,
      String feature,
      ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.construction,
                color: Colors.blue,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Coming Soon',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Text(
            '$feature feature is under development',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}