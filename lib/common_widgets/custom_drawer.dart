import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../UI_helper/responsive_layout.dart';
import '../UI_helper/currency_converter.dart';
import '../core/utils/storage/shared_preference.dart';
import '../injection_container.dart';
import '../views/AboutUs/AboutUs.dart';
import '../views/wallet/presentation/bloc/wallet_bloc.dart';
import '../views/wallet/presentation/bloc/wallet_event.dart';
import '../views/wallet/presentation/bloc/wallet_state.dart';
import '../views/MyBookings/Screen/MyBooking_Screen.dart';
import '../views/Dashboard/dashboardScreen.dart';
import '../views/Dashboard/profile/screen/Profile_screen.dart';
import '../views/Dashboard/screen/make_payment.dart';
import '../views/Dashboard/screen/support_screen.dart';
import '../views/UpcomingTrips/presentation/screen/upcoming_trip.dart';
import '../views/LogOut/presentation/bloc/logout_bloc.dart';
import '../views/LogOut/presentation/bloc/logout_event.dart';
import '../views/LogOut/presentation/bloc/logout_state.dart';
import '../views/DeleteAccount/presentation/screen/delete_account_screen.dart';
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
  double _walletBalanceInr = 0;
  String _currentCurrency = 'USD';
  WalletBloc? _walletBloc;
  StreamSubscription<WalletState>? _walletSub;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Social Media URLs - Replace with your actual URLs
  static const Map<String, String> socialLinks = {
    'linkedin': 'https://www.linkedin.com/company/wander-nova/posts/?feedView=all',
    'instagram': 'https://www.instagram.com/the.wandernova/',
    'facebook': 'https://www.facebook.com/thewandernova/?ref=1',
    'youtube': 'https://www.youtube.com/@WanderNovaTourism',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppVersion();
    _loadCurrencyPreference();
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

  void _loadCurrencyPreference() {
    final currency = CurrencyConverter.getPreferredCurrency();
    if (mounted) {
      setState(() {
        _currentCurrency = currency;
      });
    }
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    _walletBloc?.close();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSectionContainer({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
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

    if (prefManager.isLoggedIn()) {
      _walletSub?.cancel();
      _walletBloc?.close();
      _walletBloc = sl<WalletBloc>()..add(const FetchWalletBalance());
      _walletSub = _walletBloc!.stream.listen((state) {
        if (state is WalletLoaded && mounted) {
          setState(() {
            _walletBalanceInr = double.tryParse(state.balance) ?? 0.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      width: context.isMobile ? null : context.w(320),
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (_isLoggedIn) ..._buildLoggedInMenu(context),
                    if (!_isLoggedIn) ..._buildGuestMenu(context),

                    // Add Social Media Section at the bottom of the menu
                    _buildSocialMediaSection(context),
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

  // ============= SOCIAL MEDIA SECTION =============
  Widget _buildSocialMediaSection(BuildContext context) {
    return _buildSectionContainer(
      context: context,
      children: [
        _buildMenuSection(context, 'FOLLOW US'),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding.left,
            vertical: context.gapMedium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialIcon(
                context,
                icon: FontAwesomeIcons.linkedin,
                color: const Color(0xFF0A66C2),
                url: socialLinks['linkedin']!,
                label: 'LinkedIn',
              ),
              _buildSocialIcon(
                context,
                icon: FontAwesomeIcons.instagram,
                color: const Color(0xFFE4405F),
                url: socialLinks['instagram']!,
                label: 'Instagram',
              ),
              _buildSocialIcon(
                context,
                icon: FontAwesomeIcons.facebook,
                color: const Color(0xFF1877F2),
                url: socialLinks['facebook']!,
                label: 'Facebook',
              ),
              _buildSocialIcon(
                context,
                icon: FontAwesomeIcons.youtube,
                color: const Color(0xFFFF0000),
                url: socialLinks['youtube']!,
                label: 'YouTube',
              ),
            ],
          ),
        ),
        SizedBox(height: context.gapSmall),
      ],
    );
  }

  Widget _buildSocialIcon(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String url,
        required String label,
      }) {
    return InkWell(
      onTap: () => _launchSocialMedia(url, label),
      borderRadius: BorderRadius.circular(context.r(30)),
      child: Container(
        padding: EdgeInsets.all(context.w(6)),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: context.iconMedium,
            ),
            SizedBox(height: context.gapXSmall),
            Text(
              label,
              style: TextStyle(
                fontSize: context.labelSmall,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============= SOCIAL MEDIA LAUNCH FUNCTION =============
  Future<void> _launchSocialMedia(String url, String platform) async {
    try {
      // Clean the URL
      final Uri uri = Uri.parse(url);

      // Check if the URL can be launched
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Opens in external app
        );
      } else {
        // Fallback: Try to open in web view
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.inAppWebView,
          );
        } else {
          // Show error if can't launch
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot open $platform. Please try again later.'),
                backgroundColor: Colors.red.shade400,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening $platform: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  // Keep all your existing methods unchanged below this line
  // ... (rest of your existing methods: _buildLoggedInMenu, _buildGuestMenu, etc.)

  List<Widget> _buildLoggedInMenu(BuildContext context) {
    return [
      SizedBox(height: context.h(8)),
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
                horizontal: context.w(8),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(context.r(12)),
                border: Border.all(
                  color: Colors.green.shade200,
                ),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: CurrencyConverter.currencyListenable,
                builder: (context, currency, _) {
                  final converted = CurrencyConverter.convert(
                    amount: _walletBalanceInr,
                    fromCurrency: 'INR',
                    toCurrency: currency,
                  );
                  return Text(
                    CurrencyConverter.format(converted, currency),
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  );
                },
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
            icon: Icons.currency_exchange,
            title: 'Currency',
            subtitle: CurrencyConverter.isAutoDetectEnabled()
                ? '$_currentCurrency (Auto - by location)'
                : _currentCurrency,
            onTap: () => _showCurrencyPicker(context),
          ),
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
          _buildMenuItem(
            context,
            icon: Icons.delete_outline_rounded,
            title: 'Delete Account',
            subtitle: 'Permanently remove your account',
            onTap: () => _navigateTo(context, '/delete-account'),
            isDestructive: true,
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildGuestMenu(BuildContext context) {
    return [
      SizedBox(height: context.h(8)),
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
            title: 'Upcoming Trips',
            onTap: () => _navigateTo(context, '/trips'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.currency_exchange,
            title: 'Currency',
            subtitle: CurrencyConverter.isAutoDetectEnabled()
                ? '$_currentCurrency (Auto - by location)'
                : _currentCurrency,
            onTap: () => _showCurrencyPicker(context),
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
      SizedBox(height: context.h(8)),
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
        bool isDestructive = false,
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
                Icon(
                  icon,
                  size: context.iconSmall,
                  color: isDestructive
                      ? Colors.red.shade400
                      : isHighlighted
                      ? Colors.blue.shade700
                      : Colors.grey.shade700,
                ),
                SizedBox(width: context.gapMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          fontWeight: isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDestructive
                              ? Colors.red.shade400
                              : isHighlighted
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
      child: Divider(color: Colors.grey.shade200, thickness: context.h(1), height: context.h(1)),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding.right),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: context.h(1))),
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
                  letterSpacing: 0.5,
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
      margin: EdgeInsets.symmetric(horizontal: context.w(4)),
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
                  padding: EdgeInsets.all(context.w(2)),
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
      margin: EdgeInsets.symmetric(horizontal: context.w(4)),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => const LoginSignupScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
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
        case '/payment':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MakePaymentScreen(),
            ),
          );
          break;
        case '/about':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AboutUsScreen(),
            ),
          );
          break;
        case '/delete-account':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DeleteAccountScreen(),
            ),
          ).then((_) => _loadUserData());
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

  void _showCurrencyPicker(BuildContext context) {
    final selected = CurrencyConverter.isAutoDetectEnabled() ? 'AUTO' : _currentCurrency;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> select(String value) async {
              setDialogState(() => isLoading = true);
              if (value == 'AUTO') {
                final currency = await CurrencyConverter.enableAutoDetect();
                if (mounted) setState(() => _currentCurrency = currency);
              } else {
                await CurrencyConverter.setManualCurrency(value);
                if (mounted) setState(() => _currentCurrency = value);
              }
              Navigator.pop(ctx);
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(16)),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: context.w(32),
                vertical: context.h(24),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(16),
                  context.h(14),
                  context.w(16),
                  context.h(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.w(6)),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0054A0).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.currency_exchange,
                            color: const Color(0xFF0054A0),
                            size: context.iconSmall,
                          ),
                        ),
                        SizedBox(width: context.w(8)),
                        Text(
                          'Choose Currency',
                          style: GoogleFonts.poppins(
                            fontSize: context.bodyLarge,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(8)),
                    if (isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: context.h(20)),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCurrencyOption(
                                context,
                                value: 'AUTO',
                                label: 'Auto (detect by location)',
                                selectedValue: selected,
                                icon: Icons.my_location_rounded,
                                onSelect: select,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: context.h(4)),
                                child: Divider(height: 1, color: Colors.grey.shade200),
                              ),
                              ...CurrencyConverter.supportedCurrencies.entries.map(
                                    (e) => _buildCurrencyOption(
                                  context,
                                  value: e.key,
                                  label: '${e.key} · ${e.value}',
                                  selectedValue: selected,
                                  onSelect: select,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: context.h(4)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(10),
                            vertical: context.h(6),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: context.bodySmall,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrencyOption(
      BuildContext context, {
        required String value,
        required String label,
        required String selectedValue,
        required ValueChanged<String> onSelect,
        IconData? icon,
      }) {
    final isSelected = value == selectedValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(context.r(8)),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: context.h(1)),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(8),
            vertical: context.h(9),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0054A0).withOpacity(0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: context.iconSmall,
                  color: isSelected ? const Color(0xFF0054A0) : Colors.grey.shade500,
                ),
                SizedBox(width: context.w(8)),
              ],
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: context.bodySmall,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF0054A0) : Colors.black87,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: context.iconSmall,
                color: isSelected ? const Color(0xFF0054A0) : Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
              padding: EdgeInsets.all(context.w(8)),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red),
            ),
            SizedBox(width: context.w(12)),
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
                    await prefManager.clearAuth();

                    if (mounted) {
                      setState(() {
                        _isLoggedIn = false;
                        _userName = '';
                        _userEmail = '';
                        _userAvatar = null;
                      });
                    }
                  });
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Logged Out Successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                else if (state is LogoutFailed) {
                  print('Logout API failed: ${state.error.message}');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Logout failed Please try again'),
                      backgroundColor: Colors.red,
                    ),
                  );
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