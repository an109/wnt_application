import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../UI_helper/responsive_layout.dart';
import '../core/utils/storage/shared_preference.dart';
import '../views/Dashboard/dashboardScreen.dart';
import '../views/Dashboard/profile/screen/Profile_screen.dart';
import '../views/Dashboard/screen/upcoming_trip.dart';
import '../views/login/login.dart';

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      width: context.isMobile ? null : 320,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header Section with Animation
              // FadeTransition(
              //   opacity: _fadeAnimation,
              //   child: SlideTransition(
              //     position: Tween<Offset>(
              //       begin: const Offset(0, -0.1),
              //       end: Offset.zero,
              //     ).animate(_fadeAnimation),
              //     child: _buildHeader(context),
              //   ),
              // ),

              // Menu Items
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

              // Footer Section
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding.left,
        context.gapLarge + 8,
        context.horizontalPadding.left,
        context.gapLarge,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isLoggedIn
              ? [const Color(0xFF1E3A5F), const Color(0xFF2E5A8A)]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoggedIn) ...[
            // Animated Avatar
            Hero(
              tag: 'user_avatar',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: context.isMobile ? 32 : 36,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: ClipOval(
                    child: _userAvatar != null
                        ? Image.network(
                            _userAvatar!,
                            width: context.isMobile ? 64 : 72,
                            height: context.isMobile ? 64 : 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildDefaultAvatar(context),
                          )
                        : _buildDefaultAvatar(context),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.gapMedium),

            // User Name
            Text(
              _userName,
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: context.gapXSmall),

            // User Email
            if (_userEmail.isNotEmpty)
              Text(
                _userEmail,
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

            // Edit Profile Button
            SizedBox(height: context.gapSmall),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateTo(context, '/profile'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.gapSmall,
                    vertical: context.gapXSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: context.iconSmall,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      SizedBox(width: context.gapXSmall),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: context.labelSmall,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Guest Header
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey.shade300, Colors.grey.shade100],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: context.isMobile ? 32 : 36,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.person_outline,
                      size: context.isMobile ? 32 : 36,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                SizedBox(width: context.gapMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: context.titleMedium,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: context.gapXSmall),
                      Text(
                        'Sign in to access exclusive deals',
                        style: TextStyle(
                          fontSize: context.bodySmall,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.person_rounded, size: 40, color: Colors.grey.shade600),
    );
  }

  List<Widget> _buildLoggedInMenu(BuildContext context) {
    return [
      SizedBox(height: context.gapMedium),
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

      _buildDivider(context),
      _buildMenuSection(context, 'WALLET & REWARDS'),
      _buildMenuItem(
        context,
        icon: Icons.account_balance_wallet_outlined,
        title: 'My Wallet Balance',
        onTap: () => _navigateTo(context, '/wallet'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
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

      _buildDivider(context),
      _buildMenuSection(context, 'MANAGE'),
      _buildMenuItem(
        context,
        icon: Icons.cancel_outlined,
        title: 'View Cancellations',
        onTap: () => _navigateTo(context, '/cancellations'),
      ),
      _buildMenuItem(
        context,
        icon: Icons.people_outline,
        title: 'Travellers',
        onTap: () => _navigateTo(context, '/travellers'),
        subtitle: 'Added family & friends',
      ),
      _buildMenuItem(
        context,
        icon: Icons.travel_explore_outlined,
        title: 'Travel Stories',
        onTap: () => _navigateTo(context, '/stories'),
      ),

      _buildDivider(context),
      _buildMenuSection(context, 'SUPPORT'),
      _buildMenuItem(
        context,
        icon: Icons.help_outline,
        title: 'Help Center',
        onTap: () => _navigateTo(context, '/help'),
      ),
    ];
  }

  List<Widget> _buildGuestMenu(BuildContext context) {
    return [
      SizedBox(height: context.gapMedium),
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
        icon: Icons.local_offer_outlined,
        title: 'Offers & Deals',
        onTap: () => _navigateTo(context, '/offers'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.orange.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'NEW',
            style: TextStyle(
              fontSize: context.labelSmall,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
      _buildMenuItem(
        context,
        icon: Icons.hotel_outlined,
        title: 'Hotels',
        onTap: () => _navigateTo(context, '/hotels'),
      ),
      _buildMenuItem(
        context,
        icon: Icons.beach_access_outlined,
        title: 'Holiday Packages',
        onTap: () => _navigateTo(context, '/holidays'),
      ),

      _buildDivider(context),
      _buildMenuSection(context, 'EXPLORE'),
      _buildMenuItem(
        context,
        icon: Icons.trending_up_outlined,
        title: 'Popular Destinations',
        onTap: () => _navigateTo(context, '/destinations'),
      ),
      _buildMenuItem(
        context,
        icon: Icons.star_outline,
        title: 'Travel Guides',
        onTap: () => _navigateTo(context, '/guides'),
      ),
      _buildMenuItem(
        context,
        icon: Icons.article_outlined,
        title: 'Blog',
        onTap: () => _navigateTo(context, '/blog'),
      ),

      _buildDivider(context),
      _buildMenuSection(context, 'HELP'),
      _buildMenuItem(
        context,
        icon: Icons.help_outline,
        title: 'FAQs',
        onTap: () => _navigateTo(context, '/faq'),
      ),
      _buildMenuItem(
        context,
        icon: Icons.support_agent,
        title: 'Contact Support',
        onTap: () => _navigateTo(context, '/support'),
      ),
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
          letterSpacing: 0.8,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding.left - 4,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.blue.shade50.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding.left - 8,
              vertical: context.gapSmall,
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? Colors.blue.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
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

                // Title and Subtitle
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

                // Badge or Trailing
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(10),
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

                // Chevron
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
      child: Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding.right),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: _isLoggedIn
            ? _buildLogoutButton(context)
            : _buildLoginButton(context),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding.left,
              vertical: context.gapMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
            borderRadius: BorderRadius.circular(14),
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
    Navigator.pop(context); // Close drawer first

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
                      position:
                          Tween<Offset>(
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

        case '/bookings':
          // Navigate to bookings
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

        // Add more cases as needed
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
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
              final prefs = await SharedPreferences.getInstance();
              final prefManager = await PreferencesManager.create(prefs);
              await prefManager.clearUserData();
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {
                  _isLoggedIn = false;
                  _userName = '';
                  _userEmail = '';
                  _userAvatar = null;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
