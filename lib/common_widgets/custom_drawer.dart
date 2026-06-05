import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../UI_helper/responsive_layout.dart';
import '../core/utils/storage/shared_preference.dart';
import '../injection_container.dart';
import '../views/MyBookings/presentation/screen/MyBooking_Screen.dart';
import '../views/Dashboard/dashboardScreen.dart';
import '../views/Dashboard/profile/screen/Profile_screen.dart';
import '../views/Dashboard/screen/make_payment.dart';
import '../views/Dashboard/screen/support_screen.dart';
import '../views/UpcomingTrips/presentation/screen/upcoming_trip.dart';
import '../views/LogOut/presentation/bloc/logout_bloc.dart';
import '../views/LogOut/presentation/bloc/logout_event.dart';
import '../views/LogOut/presentation/bloc/logout_state.dart';
import '../views/wallet/wallet/screen/wallet_screen.dart';
import '../views/login/presentation/screen/login.dart';
import '../views/travel_stories/presentation/screen/all_travel_stories.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with SingleTickerProviderStateMixin {
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String? _userAvatar;
  String _appVersion = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppVersion();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    } catch (e) {
      setState(() {
        _appVersion = '_';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSectionContainer({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.w(8), // 8px on design
        vertical: context.h(4),   // 4px on design
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: Colors.grey.shade200,
          width: context.w(1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final prefManager = await PreferencesManager.create(prefs);

    setState(() {
      _isLoggedIn = prefManager.isLoggedIn();
      if (_isLoggedIn) {
        final userData = prefManager.getUserData();
        _userName = userData?['name'] ?? '';
        _userEmail = userData?['email'] ?? '';
        _userAvatar = userData?['avatar'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      width: context.isMobile ? null : context.w(320), // 320px on design
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (_isLoggedIn) ..._buildLoggedInMenu(context),
                    if (!_isLoggedIn) ..._buildGuestMenu(context),
                  ],
                ),
              ),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_fadeAnimation),
                  child: _buildFooter(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoggedInMenu(BuildContext context) {
    return [
      SizedBox(height: context.h(8)), // 8px on design

      _buildSectionContainer(
        context: context,
        children: [
          _buildMenuSection(context, 'MAIN MENU'),
          _buildMenuItem(
            context,
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            onTap: () => _navigateTo(context, '/dashboard'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.book_online_outlined,
            title: 'My Bookings',
            onTap: () => _navigateTo(context, '/bookings'),
            subtitle: 'View all your reservations',
          ),
          _buildMenuItem(
            context,
            icon: Icons.flight_takeoff,
            title: 'Upcoming Trips',
            onTap: () => _navigateTo(context, '/trips'),
            subtitle: 'Plan your journey',
          ),
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: 'My Profile',
            onTap: () => _navigateTo(context, '/profile'),
            subtitle: 'Manage your account',
          ),
        ],
      ),

      _buildSectionContainer(
        context: context,
        children: [
          _buildMenuSection(context, 'WALLET & REWARDS'),
          _buildMenuItem(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'My Wallet Balance',
            onTap: () => _navigateTo(context, '/wallet_balance'),
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8), // 8px on design
                vertical: context.h(4),   // 4px on design
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(context.r(12)),
                border: Border.all(
                  color: Colors.green.shade200,
                ),
              ),
              child: Text(
                '₹0',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
        ],
      ),

      _buildSectionContainer(
        context: context,
        children: [
          _buildMenuSection(context, 'MANAGE'),
          _buildMenuItem(
            context,
            icon: Icons.travel_explore_outlined,
            title: 'Travel Stories',
            onTap: () => _navigateTo(context, '/stories'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.travel_explore_outlined,
            title: 'About',
            onTap: () => _navigateTo(context, '/about'),
          ),
        ],
      ),

      SizedBox(height: context.h(8)), // 8px on design
    ];
  }

  List<Widget> _buildGuestMenu(BuildContext context) {
    return [
      SizedBox(height: context.h(8)), // 8px on design

      _buildSectionContainer(
        context: context,
        children: [
          _buildMenuItem(
            context,
            icon: Icons.flight_takeoff,
            title: 'Search Flights',
            onTap: () => _navigateTo(context, '/search'),
            subtitle: 'Find best deals',
            isHighlighted: true,
          ),
          _buildMenuItem(
            context,
            icon: Icons.beach_access_outlined,
            title: 'My Bookings',
            onTap: () => _navigateTo(context, '/bookings'),
          ),
        ],
      ),

      _buildSectionContainer(
        context: context,
        children: [
          _buildMenuSection(context, 'EXPLORE'),
          _buildMenuItem(
            context,
            icon: Icons.star_outline,
            title: 'Travel Stories',
            onTap: () => _navigateTo(context, '/stories'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.article_outlined,
            title: 'Make Payment',
            onTap: () => _navigateTo(context, '/payment'),
          ),
        ],
      ),

      _buildSectionContainer(
        context: context,
        children: [
          _buildMenuSection(context, 'HELP'),
          _buildMenuItem(
            context,
            icon: Icons.support_agent,
            title: 'Contact Support',
            onTap: () => _navigateTo(context, '/support'),
          ),
        ],
      ),

      SizedBox(height: context.h(8)), // 8px on design
    ];
  }

  Widget _buildMenuSection(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.horizontalPadding.left,
        top: context.gapLarge,
        bottom: context.gapSmall,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.labelMedium,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: context.w(0.8),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        String? subtitle,
        Widget? trailing,
        int? badgeCount,
        bool isHighlighted = false,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(12)),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding.left - context.w(4),
            vertical: context.h(2),
          ),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.blue.shade50.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding.left - context.w(8),
              vertical: context.gapSmall,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.w(8)), // 8px on design
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? Colors.blue.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(context.r(12)),
                  ),
                  child: Icon(
                    icon,
                    size: context.iconMedium,
                    color: isHighlighted
                        ? Colors.blue.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                SizedBox(width: context.gapMedium),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: context.bodyLarge,
                          fontWeight: isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isHighlighted
                              ? Colors.blue.shade700
                              : Colors.black87,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: EdgeInsets.only(top: context.gapXSmall),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: context.labelSmall,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(6),
                      vertical: context.h(2),
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (trailing != null) trailing,

                Icon(
                  Icons.chevron_right,
                  size: context.iconSmall,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding.left,
        vertical: context.gapMedium,
      ),
      child: Divider(
        color: Colors.grey.shade200,
        thickness: context.h(1),
        height: context.h(1),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding.right),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: context.h(1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoggedIn
                ? _buildLogoutButton(context)
                : _buildLoginButton(context),

            SizedBox(height: context.gapSmall),
            Center(
              child: Text(
                _appVersion,
                style: TextStyle(
                  fontSize: context.labelSmall,
                  color: Colors.grey.shade400,
                  letterSpacing: context.w(0.5),
                ),
              ),
            ),
            SizedBox(height: context.gapSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(4)), // 4px on design
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.r(14)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(context.r(14)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding.left,
              vertical: context.gapMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(context.w(2)), // 2px on design
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: context.iconMedium,
                  ),
                ),
                SizedBox(width: context.gapSmall),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(4)), // 4px on design
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
          ).then((_) => _loadUserData());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0054A0),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, context.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(14)),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login_rounded, size: context.iconMedium),
            SizedBox(width: context.gapSmall),
            Text(
              'Login / Sign Up',
              style: TextStyle(
                fontSize: context.bodyLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: context.gapSmall),
            Icon(Icons.arrow_forward_rounded, size: context.iconSmall),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context);

    Future.delayed(const Duration(milliseconds: 100), () {
      switch (route) {
        case '/dashboard':
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  DashboardScreen(userEmail: _userEmail, userName: _userName),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
          break;

        case '/payment':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MakePaymentScreen(),
            ),
          );
          break;

        case '/bookings':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyBookingScreen(),
            ),
          );
          break;

        case '/wallet_balance':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WalletScreen(),
            ),
          );
          break;

        case '/stories':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllTravelStoriesScreen(),
            ),
          );
          break;

        case '/trips':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UpcomingTripsScreen(),
            ),
          );
          break;

        case '/profile':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen()),
          );
          break;

        case '/support':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SupportScreen()),
          );
          break;
      }
    });
  }

  void _showLogoutDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.w(8)), // 8px on design
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red),
            ),
            SizedBox(width: context.w(12)), // 12px on design
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontSize: context.bodyMedium,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final logoutBloc = sl<LogoutBloc>();

              logoutBloc.stream.firstWhere(
                    (state) => state is LogoutSuccess || state is LogoutFailed,
              ).then((state) {
                if (state is LogoutSuccess) {
                  print('Logout API successful: ${state.logoutEntity.message}');

                  SharedPreferences.getInstance().then((prefs) async {
                    final prefManager = await PreferencesManager.create(prefs);
                    await prefManager.clearUserData();

                    if (mounted) {
                      setState(() {
                        _isLoggedIn = false;
                        _userName = '';
                        _userEmail = '';
                        _userAvatar = null;
                      });
                    }
                  });
                } else if (state is LogoutFailed) {
                  print('Logout API failed: ${state.error.message}');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: ${state.error.message ?? 'Please try again'}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              });

              logoutBloc.add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
            ),
            child: Text(
              'Sign Out',
              style: TextStyle(fontSize: context.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}