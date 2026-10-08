import 'package:wander_nova/views/splash/splash_screen.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../UI_helper/responsive_layout.dart';
import '../UI_helper/currency_converter.dart';
import '../core/utils/storage/shared_preference.dart';
import '../injection_container.dart';
import '../views/AboutUs/general_info_screen.dart';
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
import '../views/currency/presentation/screen/currency_screen.dart';
import '../views/wallet/wallet/screen/rewards_screen.dart';
import '../views/wallet/wallet/screen/wallet_screen.dart';
import '../views/login/presentation/screen/login.dart';
import '../views/travel_stories/presentation/screen/all_travel_stories.dart';
import '../core/error/data_state.dart';
import '../views/WalletStatus/domain/entity/loyality_entity.dart';
import '../views/WalletStatus/presentation/bloc/loyalty_bloc.dart';
import '../views/WalletStatus/presentation/bloc/loyalty_event.dart';
import '../views/WalletStatus/presentation/bloc/loyalty_state.dart';
import '../views/WalletStatus/presentation/screen/loyalty_tier_screen.dart';
import '../views/notifications/notification_service.dart';
import '../views/notifications/notifications_screen.dart';
import '../views/ReferCode/presentation/screen/refer_earn_screen.dart';

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
  String _userPhone = '';
  String? _userAvatar;
  /// Loyalty tier label for the second quick tile (e.g. "Bronze").
  String? _tierLabel;

  /// Loyalty tier key ("bronze" … "platinum"); themes the profile card.
  /// Cached so the card opens in the right colours before the API answers.
  String? _tierKey;
  String get _tierCacheKey => 'drawer_loyalty_tier:${_userEmail.toLowerCase()}';
  /// Unread count from the notification feed (orange badge).
  int _unreadNotifications = 0;
  LoyaltyBloc? _loyaltyBloc;
  StreamSubscription<LoyaltyState>? _loyaltySub;
  String _appVersion = '';
  double _walletBalanceInr = 0;
  String _currentCurrency = 'USD';
  WalletBloc? _walletBloc;
  StreamSubscription<WalletState>? _walletSub;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Social Media URLs - Replace with your actual URLs
  static const Map<String, String> socialLinks = {
    'linkedin':
        'https://www.linkedin.com/company/wander-nova/posts/?feedView=all',
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
    _loyaltySub?.cancel();
    _loyaltyBloc?.close();
    _animationController.dispose();
    super.dispose();
  }

  /// Login and the Profile screen save `firstname` / `lastname` (no `name`
  /// key), so build the display name from those; a plain `name` or other
  /// spellings are still accepted.
  static String _nameFrom(Map<String, dynamic>? data) {
    if (data == null) return '';
    String read(List<String> keys) {
      for (final k in keys) {
        final v = (data[k] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final full = read(['name', 'full_name', 'fullName']);
    if (full.isNotEmpty) return full;
    final first = read(['firstname', 'first_name', 'firstName']);
    final last = read(['lastname', 'last_name', 'lastName']);
    return '$first $last'.trim();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final prefManager = await PreferencesManager.create(prefs);

    setState(() {
      _isLoggedIn = prefManager.isLoggedIn();
      if (_isLoggedIn) {
        final userData = prefManager.getUserData();
        _userName = _nameFrom(userData);
        _userEmail = userData?['email'] ?? '';
        _userPhone = (userData?['phone'] ??
                userData?['mobile'] ??
                userData?['phone_number'] ??
                '')
            .toString();
        _userAvatar = userData?['avatar'];
      }
    });

    if (prefManager.isLoggedIn()) {
      final cachedTier = prefs.getString(_tierCacheKey);
      if (cachedTier != null && _tierKey == null && mounted) {
        setState(() => _tierKey = cachedTier);
      }
      _walletSub?.cancel();
      _walletBloc?.close();
      _walletBloc = sl<WalletBloc>()..add(const FetchWalletBalance());
      NotificationService().unreadCount().then((count) {
        if (mounted) setState(() => _unreadNotifications = count);
      }).catchError((_) {});
      _loyaltySub?.cancel();
      _loyaltyBloc?.close();
      _loyaltyBloc = sl<LoyaltyBloc>()..add(FetchUserLoyalty());
      _loyaltySub = _loyaltyBloc!.stream.listen((state) {
        if (state is LoyaltyLoaded && mounted) {
          final data = state.dataState;
          if (data is DataSuccess<LoyaltyEntity> && data.data != null) {
            final label = data.data!.tierLabel.trim();
            final key = data.data!.tier.trim().toLowerCase();
            setState(() {
              _tierLabel = label.isEmpty ? null : label;
              _tierKey = key.isEmpty ? null : key;
            });
            if (key.isNotEmpty) prefs.setString(_tierCacheKey, key);
          }
        }
      });
      _walletSub = _walletBloc!.stream.listen((state) {
        if (state is WalletLoaded && mounted) {
          setState(() {
            _walletBalanceInr = double.tryParse(state.balance) ?? 0.0;
          });
        }
      });
    }
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
          await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
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

  // ======================================================================
  // UI — Figma "menu" (node 1839:8497, 412px frame, hence `context.fx`).
  // ======================================================================

  static const Color _ink = Color(0xFF111527);
  static const Color _muted = Color(0xFF757575);
  static const Color _line = Color(0xFFE6E9EF);

  @override
  Widget build(BuildContext context) {
    final panelWidth = context.fx(316).clamp(0.0, context.screenWidth * 0.82);
    final closeSlot = context.fx(52);

    return Drawer(
      elevation: 0,
      width: panelWidth + closeSlot,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: panelWidth, child: _buildPanel(context)),
            // Figma: the close button floats just outside the panel. The
            // rest of this strip also closes the drawer, like the scrim.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: context.statusBarHeight + context.fx(28),
                    ),
                    child: Semantics(
                      button: true,
                      label: 'Close menu',
                      child: Container(
                        width: context.fx(36),
                        height: context.fx(36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(context.fx(10)),
                        ),
                        child: Icon(Icons.close_rounded, size: context.fx(22), color: _ink),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(context.fx(20))),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD7EEFE), Color(0xFFF4F7FB), Color(0xFFF4F7FB)],
            stops: [0.0, 0.22, 1.0],
          ),
        ),
        child: SafeArea(
          right: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.fx(16),
                context.fx(16),
                context.fx(16),
                context.fx(24),
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildProfileCard(context),
                SizedBox(height: context.fx(24)),
                _buildQuickTiles(context),
                SizedBox(height: context.fx(24)),
                ..._isLoggedIn
                    ? _buildLoggedInMenu(context)
                    : _buildGuestMenu(context),
                SizedBox(height: context.fx(56)),
                _buildSocialMediaSection(context),
                SizedBox(height: context.fx(28)),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ profile

  Widget _buildProfileCard(BuildContext context) {
    final subtitle = _isLoggedIn
        ? (_userPhone.isNotEmpty ? _userPhone : _userEmail)
        : 'Log in to manage your trips';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Profile screen (Figma "profile"); guests are sent to log in.
      onTap: () => _isLoggedIn
          ? _navigateTo(context, '/profile')
          : _openLogin(context),
      child: Container(
        height: context.fx(84),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.fx(12)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: _theme.card,
          ),
          boxShadow: [
            BoxShadow(color: _theme.shadow, blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Soft decorative circles from the design.
            Positioned(
              right: -context.fx(18),
              top: -context.fx(26),
              child: _bubble(context, 78),
            ),
            Positioned(
              right: context.fx(26),
              bottom: -context.fx(38),
              child: _bubble(context, 70),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.fx(10)),
              child: Row(
                children: [
                  _buildAvatar(context),
                  SizedBox(width: context.fx(12)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoggedIn && _userName.isNotEmpty
                              ? _userName
                              : 'Hello, Traveller',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.ffs(18),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: context.fx(2)),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.ffs(12),
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        if (!_isLoggedIn) ...[
                          SizedBox(height: context.fx(6)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.fx(10),
                              vertical: context.fx(3),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(context.fx(12)),
                            ),
                            child: Text(
                              'Login / Sign Up',
                              style: TextStyle(
                                fontSize: context.ffs(11),
                                fontWeight: FontWeight.w600,
                                color: AppColors.AppBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Figma: camera badge in the corner — opens the profile, where
            // the photo is changed.
            if (_isLoggedIn)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(context.fx(5)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(context.fx(10)),
                      bottomRight: Radius.circular(context.fx(12)),
                    ),
                  ),
                  child: Icon(Icons.photo_camera_rounded, size: context.fx(16), color: _theme.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _TierTheme get _theme => _isLoggedIn ? _TierTheme.of(_tierKey) : _TierTheme.standard;

  Widget _bubble(BuildContext context, double size) => Container(
    width: context.fx(size),
    height: context.fx(size),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.16),
    ),
  );

  Widget _buildAvatar(BuildContext context) {
    final size = context.fx(64);
    final initials = _userName.trim().isEmpty
        ? null
        : _userName.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();
    final placeholder = Container(
      color: _theme.tileTint,
      alignment: Alignment.center,
      child: initials == null
          ? Icon(Icons.person_rounded, size: context.fx(34), color: _theme.accent)
          : Text(
              initials,
              style: TextStyle(
                fontSize: context.ffs(20),
                fontWeight: FontWeight.w700,
                color: _theme.accent,
              ),
            ),
    );
    final avatar = _userAvatar;

    return SizedBox(
      width: size + context.fx(6),
      height: size + context.fx(6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            margin: EdgeInsets.only(top: context.fx(6)),
            padding: EdgeInsets.all(context.fx(3)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: _theme.ring),
            ),
            child: ClipOval(
              child: avatar != null && avatar.isNotEmpty
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholder,
                    )
                  : placeholder,
            ),
          ),
          if (_isLoggedIn)
            Positioned(
              right: -context.fx(2),
              top: -context.fx(2),
              child: Transform.rotate(
                angle: 0.45,
                child: Icon(
                  FontAwesomeIcons.crown.data,
                  size: context.fx(16),
                  color: _theme.crown,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- quick tiles

  Widget _buildQuickTiles(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickTile(
            context,
            icon: Icons.luggage_rounded,
            iconColor: AppColors.AppBlue,
            tint: const Color(0xFFEAF4FF),
            label: 'My Trip',
            // My Bookings links on to the Dashboard and Upcoming Trips, so
            // every account screen stays one or two taps away.
            onTap: () => _isLoggedIn
                ? _navigateTo(context, '/bookings')
                : _openLogin(context),
          ),
        ),
        SizedBox(width: context.fx(12)),
        Expanded(
          child: _quickTile(
            context,
            icon: Icons.workspace_premium_rounded,
            iconColor: _isLoggedIn && _tierKey != null ? _theme.accent : const Color(0xFFE0A100),
            tint: _isLoggedIn && _tierKey != null ? _theme.tileTint : const Color(0xFFFFF4CC),
            label: _tierLabel ?? 'Membership',
            onTap: () => _isLoggedIn
                ? _navigateTo(context, '/tier')
                : _openLogin(context),
          ),
        ),
        SizedBox(width: context.fx(12)),
        Expanded(
          child: _quickTile(
            context,
            icon: Icons.favorite_border_rounded,
            iconColor: const Color(0xFFE5484D),
            tint: const Color(0xFFFDECEF),
            label: 'Wishlists',
            onTap: () => _comingSoon(context, 'Wishlists'),
          ),
        ),
      ],
    );
  }

  Widget _quickTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color tint,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.fx(12)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.fx(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.fx(12)),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: [
              Container(
                width: context.fx(40),
                height: context.fx(40),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(context.fx(8)),
                ),
                child: Icon(icon, size: context.fx(22), color: iconColor),
              ),
              SizedBox(height: context.fx(8)),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.ffs(12),
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------- menu groups

  List<Widget> _buildLoggedInMenu(BuildContext context) {
    return [
      _buildSectionContainer(
        context: context,
        children: [
          _buildMenuItem(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            onTap: () => _navigateTo(context, '/notifications'),
            trailing: _unreadNotifications > 0
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.fx(8),
                      vertical: context.fx(2),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEE7330),
                      borderRadius: BorderRadius.circular(context.fx(10)),
                    ),
                    child: Text(
                      _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                      style: TextStyle(
                        fontSize: context.ffs(11),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          _buildMenuItem(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            onTap: () => _navigateTo(context, '/wallet_balance'),
            trailing: ValueListenableBuilder<String>(
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
                    fontSize: context.ffs(12),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E9E5A),
                  ),
                );
              },
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.card_giftcard_rounded,
            title: 'Refer & Earn',
            onTap: () => _navigateTo(context, '/refer'),
            showDivider: false,
          ),
        ],
      ),
      SizedBox(height: context.fx(24)),
      _buildAboutSection(context),
      SizedBox(height: context.fx(24)),
      _buildSettingsSection(context, includeDeleteAccount: true),
      SizedBox(height: context.fx(24)),
      _buildLogoutButton(context),
    ];
  }

  List<Widget> _buildGuestMenu(BuildContext context) {
    return [
      _buildAboutSection(context),
      SizedBox(height: context.fx(24)),
      _buildSettingsSection(context, includeDeleteAccount: false),
      SizedBox(height: context.fx(24)),
      _buildLoginButton(context),
    ];
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSectionContainer(
      context: context,
      title: 'About',
      children: [
        _buildMenuItem(
          context,
          icon: Icons.support_agent_rounded,
          title: 'Customer Support',
          onTap: () => _navigateTo(context, '/support'),
        ),
        _buildMenuItem(
          context,
          icon: Icons.info_rounded,
          title: 'General Information',
          onTap: () => _navigateTo(context, '/about'),
        ),
        // Not in the Figma menu; kept so stories stay reachable.
        _buildMenuItem(
          context,
          icon: Icons.auto_stories_outlined,
          title: 'Travel Stories',
          onTap: () => _navigateTo(context, '/stories'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required bool includeDeleteAccount,
  }) {
    return _buildSectionContainer(
      context: context,
      title: 'Settings',
      children: [
        _buildMenuItem(
          context,
          icon: Icons.payments_outlined,
          title: 'Currency',
          subtitle: CurrencyConverter.isAutoDetectEnabled()
              ? '$_currentCurrency (Auto)'
              : _currentCurrency,
          onTap: () => _showCurrencyPicker(context),
        ),
        _buildMenuItem(
          context,
          icon: Icons.translate_rounded,
          title: 'Language',
          subtitle: 'English',
          onTap: () => _comingSoon(context, 'More languages'),
          showDivider: includeDeleteAccount,
        ),
        // Not in the Figma menu; account deletion must stay reachable
        // (store policy).
        if (includeDeleteAccount)
          _buildMenuItem(
            context,
            icon: Icons.delete_outline_rounded,
            title: 'Delete Account',
            onTap: () => _navigateTo(context, '/delete-account'),
            isDestructive: true,
            showDivider: false,
          ),
      ],
    );
  }

  Widget _buildSectionContainer({
    required BuildContext context,
    required List<Widget> children,
    String? title,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: _line),
      ),
      padding: EdgeInsets.symmetric(vertical: context.fx(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.fx(12),
                context.fx(10),
                context.fx(12),
                0,
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: context.ffs(11),
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
            ),
          ...children,
        ],
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
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    final color = isDestructive ? const Color(0xFFE5484D) : _ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.fx(12)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.fx(12)),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: _line))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: context.fx(18),
                color: isDestructive ? color : const Color(0xFF4B5563),
              ),
              SizedBox(width: context.fx(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.ffs(14),
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.ffs(10), color: _muted),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing,
                SizedBox(width: context.fx(6)),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: context.fx(22),
                color: isDestructive ? color : AppColors.AppBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------- log out / log in

  Widget _buildLogoutButton(BuildContext context) {
    return _actionCard(
      context,
      icon: Icons.logout_rounded,
      iconColor: const Color(0xFFE5484D),
      label: 'Log out',
      onTap: () => _showLogoutDialog(context),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return _actionCard(
      context,
      icon: Icons.login_rounded,
      iconColor: AppColors.AppBlue,
      label: 'Login / Sign Up',
      onTap: () => _openLogin(context),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.fx(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.fx(12)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.fx(12),
            vertical: context.fx(12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.fx(12)),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Icon(icon, size: context.fx(18), color: iconColor),
              SizedBox(width: context.fx(10)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.ffs(14),
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const LoginSignupScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ).then((_) => _loadUserData());
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature coming soon'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ------------------------------------------------- social + footer

  Widget _buildSocialMediaSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Show us some love',
          style: TextStyle(
            fontSize: context.ffs(11),
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
        SizedBox(height: context.fx(8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              context,
              icon: FontAwesomeIcons.instagram.data,
              background: const LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF4F5BD5)],
              ),
              url: socialLinks['instagram']!,
              label: 'Instagram',
            ),
            _buildSocialIcon(
              context,
              icon: FontAwesomeIcons.linkedinIn.data,
              color: const Color(0xFF0A66C2),
              url: socialLinks['linkedin']!,
              label: 'LinkedIn',
            ),
            _buildSocialIcon(
              context,
              icon: FontAwesomeIcons.youtube.data,
              color: const Color(0xFFFF0000),
              url: socialLinks['youtube']!,
              label: 'YouTube',
            ),
            _buildSocialIcon(
              context,
              icon: FontAwesomeIcons.facebookF.data,
              color: const Color(0xFF1877F2),
              url: socialLinks['facebook']!,
              label: 'Facebook',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(
    BuildContext context, {
    required IconData icon,
    required String url,
    required String label,
    Color? color,
    Gradient? background,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.fx(5)),
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: () => _launchSocialMedia(url, label),
          borderRadius: BorderRadius.circular(context.fx(6)),
          child: Container(
            width: context.fx(26),
            height: context.fx(26),
            decoration: BoxDecoration(
              color: color,
              gradient: background,
              borderRadius: BorderRadius.circular(context.fx(6)),
            ),
            child: Icon(icon, size: context.fx(15), color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/wander_logo.png',
          height: context.fx(34),
          fit: BoxFit.contain,
        ),
        if (_appVersion.isNotEmpty && _appVersion != '_') ...[
          SizedBox(height: context.fx(6)),
          Text(
            _appVersion,
            style: TextStyle(
              fontSize: context.ffs(10),
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
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
            MaterialPageRoute(builder: (_) => MakePaymentScreen()),
          );
          break;
        case '/about':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeneralInfoScreen()),
          );
          break;
        case '/delete-account':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
          ).then((_) => _loadUserData());
          break;
        case '/bookings':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MyBookingScreen()),
          );
          break;
        case '/wallet_balance':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WalletScreen()),
          );
          break;
        case '/refer':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReferEarnScreen()),
          );
          break;
        case '/notifications':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
          break;
        case '/tier':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoyaltyTierScreen()),
          );
          break;
        case '/rewards':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RewardsScreen()),
          );
          break;
        case '/stories':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AllTravelStoriesScreen()),
          );
          break;
        case '/trips':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UpcomingTripsScreen()),
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

  /// Opens the currency screen (Figma `CHOOSE Currency`). It applies the
  /// choice itself through CurrencyConverter and pops the saved code, so this
  /// only has to mirror it into the drawer's own label.
  Future<void> _showCurrencyPicker(BuildContext context) async {
    final saved = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CurrencyScreen()),
    );
    if (saved != null && mounted) {
      setState(() => _currentCurrency = saved);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(24)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.w(12)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(22),
            context.w(30),
            context.w(22),
            context.w(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: context.w(64),
                width: context.w(64),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: context.w(34),
                ),
              ),
              SizedBox(height: context.w(22)),
              Text(
                'Logout?',
                style: TextStyle(
                  fontSize: context.fs(20),
                  fontWeight: FontWeight.w600,
                  color: AppColors.authInk,
                ),
              ),
              SizedBox(height: context.w(8)),
              Text(
                'Are you sure, Do you want to Logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w500,
                  color: AppColors.authSubtle,
                ),
              ),
              SizedBox(height: context.w(26)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: context.w(46),
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppColors.OrangeColor,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.w(12)),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: context.fs(14),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: AppColors.OrangeColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(14)),
                  Expanded(
                    child: SizedBox(
                      height: context.w(46),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.OrangeColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.w(12)),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);

                          final logoutBloc = sl<LogoutBloc>();

                          logoutBloc.stream
                              .firstWhere(
                                (state) =>
                                    state is LogoutSuccess ||
                                    state is LogoutFailed,
                              )
                              .then((state) {
                                if (state is LogoutSuccess) {
                                  print(
                                    'Logout API successful: ${state.logoutEntity.message}',
                                  );

                                  SharedPreferences.getInstance().then((
                                    prefs,
                                  ) async {
                                    final prefManager =
                                        await PreferencesManager.create(prefs);
                                    await prefManager.clearUserData();
                                    await prefManager.clearAuth();
                                    await prefs.remove(_tierCacheKey);

                                    if (mounted) {
                                      setState(() {
                                        _isLoggedIn = false;
                                        _userName = '';
                                        _userEmail = '';
                                        _userPhone = '';
                                        _userAvatar = null;
                                        _tierLabel = null;
                                        _tierKey = null;
                                      });
                                    }
                                    rootNavigator.pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const SplashScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  });
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Logged Out Successfully'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else if (state is LogoutFailed) {
                                  print(
                                    'Logout API failed: ${state.error.message}',
                                  );
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Logout failed Please try again',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              });

                          logoutBloc.add(LogoutRequested());
                        },
                        child: Text(
                          'LOGOUT',
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile-card colours per loyalty tier (Figma "golden menu" and its
/// bronze / silver / platinum siblings). Unknown tier or guest → blue.
class _TierTheme {
  final List<Color> card;
  final Color shadow;
  final List<Color> ring;
  final Color crown;

  /// Camera badge + tier tile icon.
  final Color accent;
  final Color tileTint;

  const _TierTheme({
    required this.card,
    required this.shadow,
    required this.ring,
    required this.crown,
    required this.accent,
    required this.tileTint,
  });

  static const standard = _TierTheme(
    card: [Color(0xFF5DB4F5), Color(0xFF8FD0FF)],
    shadow: Color(0x332D8FD8),
    ring: [Color(0xFFE0A548), Color(0xFFB8741E)],
    crown: Color(0xFFE39B3B),
    accent: Color(0xFF2D8FD8),
    tileTint: Color(0xFFEAF4FF),
  );

  static const bronze = _TierTheme(
    card: [Color(0xFF9A5A32), Color(0xFFC7895B)],
    shadow: Color(0x40804A26),
    ring: [Color(0xFFE6A877), Color(0xFF8C4F2A)],
    crown: Color(0xFFF0B888),
    accent: Color(0xFFB06A3B),
    tileTint: Color(0xFFF8E9DE),
  );

  static const silver = _TierTheme(
    card: [Color(0xFF7D8896), Color(0xFFB4BFCB)],
    shadow: Color(0x406B7684),
    ring: [Color(0xFFF1F3F6), Color(0xFF9AA4B1)],
    crown: Color(0xFFF4F6F8),
    accent: Color(0xFF6B7684),
    tileTint: Color(0xFFEEF1F4),
  );

  static const gold = _TierTheme(
    card: [Color(0xFFB7862C), Color(0xFFD6A54A)],
    shadow: Color(0x40A3741E),
    ring: [Color(0xFFF6D27A), Color(0xFFB8741E)],
    crown: Color(0xFFF6C35A),
    accent: Color(0xFFC08A2E),
    tileTint: Color(0xFFFFF4CC),
  );

  static const platinum = _TierTheme(
    card: [Color(0xFF2F3542), Color(0xFF606A7B)],
    shadow: Color(0x402F3542),
    ring: [Color(0xFFF2F1EF), Color(0xFFA7A9AC)],
    crown: Color(0xFFE5E4E2),
    accent: Color(0xFF3E4655),
    tileTint: Color(0xFFECEDEF),
  );

  static _TierTheme of(String? tier) => switch (tier) {
    'bronze' => bronze,
    'silver' => silver,
    'gold' => gold,
    'platinum' => platinum,
    _ => standard,
  };
}

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:wander_nova/core/resources/app_colours.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import '../UI_helper/responsive_layout.dart';
// import '../UI_helper/currency_converter.dart';
// import '../core/utils/storage/shared_preference.dart';
// import '../injection_container.dart';
// import '../views/AboutUs/AboutUs.dart';
// import '../views/wallet/presentation/bloc/wallet_bloc.dart';
// import '../views/wallet/presentation/bloc/wallet_event.dart';
// import '../views/wallet/presentation/bloc/wallet_state.dart';
// import '../views/MyBookings/Screen/MyBooking_Screen.dart';
// import '../views/Dashboard/dashboardScreen.dart';
// import '../views/Dashboard/profile/screen/Profile_screen.dart';
// import '../views/Dashboard/screen/make_payment.dart';
// import '../views/Dashboard/screen/support_screen.dart';
// import '../views/UpcomingTrips/presentation/screen/upcoming_trip.dart';
// import '../views/LogOut/presentation/bloc/logout_bloc.dart';
// import '../views/LogOut/presentation/bloc/logout_event.dart';
// import '../views/LogOut/presentation/bloc/logout_state.dart';
// import '../views/DeleteAccount/presentation/screen/delete_account_screen.dart';
// import '../views/currency/presentation/screen/currency_screen.dart';
// import '../views/wallet/wallet/screen/rewards_screen.dart';
// import '../views/wallet/wallet/screen/wallet_screen.dart';
// import '../views/login/presentation/screen/login.dart';
// import '../views/travel_stories/presentation/screen/all_travel_stories.dart';
//
// class CustomDrawer extends StatefulWidget {
//   const CustomDrawer({super.key});
//
//   @override
//   State<CustomDrawer> createState() => _CustomDrawerState();
// }
//
// class _CustomDrawerState extends State<CustomDrawer>
//     with SingleTickerProviderStateMixin {
//   bool _isLoggedIn = false;
//   String _userName = '';
//   String _userEmail = '';
//   String? _userAvatar;
//   String _appVersion = '';
//   double _walletBalanceInr = 0;
//   String _currentCurrency = 'USD';
//   WalletBloc? _walletBloc;
//   StreamSubscription<WalletState>? _walletSub;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   // Social Media URLs - Replace with your actual URLs
//   static const Map<String, String> socialLinks = {
//     'linkedin':
//         'https://www.linkedin.com/company/wander-nova/posts/?feedView=all',
//     'instagram': 'https://www.instagram.com/the.wandernova/',
//     'facebook': 'https://www.facebook.com/thewandernova/?ref=1',
//     'youtube': 'https://www.youtube.com/@WanderNovaTourism',
//   };
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     _loadAppVersion();
//     _loadCurrencyPreference();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 400),
//       vsync: this,
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutCubic,
//     );
//     _animationController.forward();
//   }
//
//   Future<void> _loadAppVersion() async {
//     try {
//       final packageInfo = await PackageInfo.fromPlatform();
//       setState(() {
//         _appVersion = 'v${packageInfo.version}';
//       });
//     } catch (e) {
//       setState(() {
//         _appVersion = '_';
//       });
//     }
//   }
//
//   void _loadCurrencyPreference() {
//     final currency = CurrencyConverter.getPreferredCurrency();
//     if (mounted) {
//       setState(() {
//         _currentCurrency = currency;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _walletSub?.cancel();
//     _walletBloc?.close();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Widget _buildSectionContainer({
//     required BuildContext context,
//     required List<Widget> children,
//   }) {
//     return Container(
//       margin: EdgeInsets.symmetric(
//         horizontal: context.w(8),
//         vertical: context.h(4),
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.r(12)),
//         border: Border.all(color: Colors.grey.shade200, width: 1),
//       ),
//       child: Column(mainAxisSize: MainAxisSize.min, children: children),
//     );
//   }
//
//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final prefManager = await PreferencesManager.create(prefs);
//
//     setState(() {
//       _isLoggedIn = prefManager.isLoggedIn();
//       if (_isLoggedIn) {
//         final userData = prefManager.getUserData();
//         _userName = userData?['name'] ?? '';
//         _userEmail = userData?['email'] ?? '';
//         _userAvatar = userData?['avatar'];
//       }
//     });
//
//     if (prefManager.isLoggedIn()) {
//       _walletSub?.cancel();
//       _walletBloc?.close();
//       _walletBloc = sl<WalletBloc>()..add(const FetchWalletBalance());
//       _walletSub = _walletBloc!.stream.listen((state) {
//         if (state is WalletLoaded && mounted) {
//           setState(() {
//             _walletBalanceInr = double.tryParse(state.balance) ?? 0.0;
//           });
//         }
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       elevation: 0,
//       width: context.isMobile
//           ? context.w(304).clamp(0.0, context.screenWidth * 0.85)
//           : context.w(320),
//       child: MediaQuery.withClampedTextScaling(
//         maxScaleFactor: 1.3,
//         child: Container(
//           color: Colors.white,
//           child: SafeArea(
//             child: Column(
//               children: [
//                 // Menu Items
//                 Expanded(
//                   child: ListView(
//                     padding: EdgeInsets.zero,
//                     physics: const BouncingScrollPhysics(),
//                     children: [
//                       if (_isLoggedIn) ..._buildLoggedInMenu(context),
//                       if (!_isLoggedIn) ..._buildGuestMenu(context),
//
//                       // Add Social Media Section at the bottom of the menu
//                       _buildSocialMediaSection(context),
//                     ],
//                   ),
//                 ),
//
//                 // Footer Section
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: SlideTransition(
//                     position: Tween<Offset>(
//                       begin: const Offset(0, 0.1),
//                       end: Offset.zero,
//                     ).animate(_fadeAnimation),
//                     child: _buildFooter(context),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ============= SOCIAL MEDIA SECTION =============
//   Widget _buildSocialMediaSection(BuildContext context) {
//     return _buildSectionContainer(
//       context: context,
//       children: [
//         _buildMenuSection(context, 'FOLLOW US'),
//         Padding(
//           padding: EdgeInsets.symmetric(
//             horizontal: context.horizontalPadding.left,
//             vertical: context.gapMedium,
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildSocialIcon(
//                 context,
//                 icon: FontAwesomeIcons.linkedin.data,
//                 color: const Color(0xFF0A66C2),
//                 url: socialLinks['linkedin']!,
//                 label: 'LinkedIn',
//               ),
//               _buildSocialIcon(
//                 context,
//                 icon: FontAwesomeIcons.instagram.data,
//                 color: const Color(0xFFE4405F),
//                 url: socialLinks['instagram']!,
//                 label: 'Instagram',
//               ),
//               _buildSocialIcon(
//                 context,
//                 icon: FontAwesomeIcons.facebook.data,
//                 color: const Color(0xFF1877F2),
//                 url: socialLinks['facebook']!,
//                 label: 'Facebook',
//               ),
//               _buildSocialIcon(
//                 context,
//                 icon: FontAwesomeIcons.youtube.data,
//                 color: const Color(0xFFFF0000),
//                 url: socialLinks['youtube']!,
//                 label: 'YouTube',
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: context.gapSmall),
//       ],
//     );
//   }
//
//   Widget _buildSocialIcon(
//     BuildContext context, {
//     required IconData icon,
//     required Color color,
//     required String url,
//     required String label,
//   }) {
//     return Expanded(
//       child: InkWell(
//         onTap: () => _launchSocialMedia(url, label),
//         borderRadius: BorderRadius.circular(context.r(30)),
//         child: Container(
//           padding: EdgeInsets.symmetric(
//             vertical: context.w(6),
//             horizontal: context.w(2),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, color: color, size: context.iconMedium),
//               SizedBox(height: context.gapXSmall),
//               FittedBox(
//                 fit: BoxFit.scaleDown,
//                 child: Text(
//                   label,
//                   maxLines: 1,
//                   style: TextStyle(
//                     fontSize: context.labelSmall,
//                     color: Colors.grey.shade600,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ============= SOCIAL MEDIA LAUNCH FUNCTION =============
//   Future<void> _launchSocialMedia(String url, String platform) async {
//     try {
//       // Clean the URL
//       final Uri uri = Uri.parse(url);
//
//       // Check if the URL can be launched
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(
//           uri,
//           mode: LaunchMode.externalApplication, // Opens in external app
//         );
//       } else {
//         // Fallback: Try to open in web view
//         if (await canLaunchUrl(Uri.parse(url))) {
//           await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
//         } else {
//           // Show error if can't launch
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Cannot open $platform. Please try again later.'),
//                 backgroundColor: Colors.red.shade400,
//               ),
//             );
//           }
//         }
//       }
//     } catch (e) {
//       // Handle any errors
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error opening $platform: ${e.toString()}'),
//             backgroundColor: Colors.red.shade400,
//           ),
//         );
//       }
//     }
//   }
//
//   // Keep all your existing methods unchanged below this line
//   // ... (rest of your existing methods: _buildLoggedInMenu, _buildGuestMenu, etc.)
//
//   List<Widget> _buildLoggedInMenu(BuildContext context) {
//     return [
//       SizedBox(height: context.h(8)),
//       _buildSectionContainer(
//         context: context,
//         children: [
//           _buildMenuSection(context, 'MAIN MENU'),
//           _buildMenuItem(
//             context,
//             icon: Icons.dashboard_outlined,
//             title: 'Dashboard',
//             onTap: () => _navigateTo(context, '/dashboard'),
//           ),
//           _buildMenuItem(
//             context,
//             icon: Icons.book_online_outlined,
//             title: 'My Bookings',
//             onTap: () => _navigateTo(context, '/bookings'),
//             subtitle: 'View all your reservations',
//           ),
//           _buildMenuItem(
//             context,
//             icon: Icons.flight_takeoff,
//             title: 'Upcoming Trips',
//             onTap: () => _navigateTo(context, '/trips'),
//             subtitle: 'Plan your journey',
//           ),
//           _buildMenuItem(
//             context,
//             icon: Icons.person_outline,
//             title: 'My Profile',
//             onTap: () => _navigateTo(context, '/profile'),
//             subtitle: 'Manage your account',
//           ),
//         ],
//       ),
//       _buildSectionContainer(
//         context: context,
//         children: [
//           _buildMenuSection(context, 'WALLET & REWARDS'),
//           _buildMenuItem(
//             context,
//             icon: Icons.account_balance_wallet_outlined,
//             title: 'My Wallet Balance',
//             onTap: () => _navigateTo(context, '/wallet_balance'),
//             trailing: Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: context.w(8),
//                 vertical: context.h(4),
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(context.r(12)),
//                 border: Border.all(color: Colors.green.shade200),
//               ),
//               child: ValueListenableBuilder<String>(
//                 valueListenable: CurrencyConverter.currencyListenable,
//                 builder: (context, currency, _) {
//                   final converted = CurrencyConverter.convert(
//                     amount: _walletBalanceInr,
//                     fromCurrency: 'INR',
//                     toCurrency: currency,
//                   );
//                   return Text(
//                     CurrencyConverter.format(converted, currency),
//                     style: TextStyle(
//                       fontSize: context.labelSmall,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.green.shade700,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           // Refer & Earn and Loyalty Tier used to sit inside the wallet
//           // screen. The redesign leaves that screen as balance plus history,
//           // so both live on their own screen reached from here.
//           _buildMenuItem(
//             context,
//             icon: Icons.card_giftcard_outlined,
//             title: 'Rewards',
//             subtitle: 'Refer & Earn and your loyalty tier',
//             onTap: () => _navigateTo(context, '/rewards'),
//           ),
//         ],
//       ),
//       _buildSectionContainer(
//         context: context,
//         children: [
//           _buildMenuSection(context, 'MANAGE'),
//           _buildMenuItem(
//             context,
//             icon: Icons.currency_exchange,
//             title: 'Currency',
//             subtitle: CurrencyConverter.isAutoDetectEnabled()
//                 ? '$_currentCurrency (Auto - by location)'
//                 : _currentCurrency,
//             onTap: () => _showCurrencyPicker(context),
//           ),
//           _buildMenuItem(
//             context,
//             icon: Icons.travel_explore_outlined,
//             title: 'Travel Stories',
//             onTap: () => _navigateTo(context, '/stories'),
//           ),
//           _buildMenuItem(
//             context,
//             icon: Icons.travel_explore_outlined,
//             title: 'About',
//             onTap: () => _navigateTo(context, '/about'),
//           ),
//           _buildMenuItem(
//             context,
//             icon: Icons.delete_outline_rounded,
//             title: 'Delete Account',
//             subtitle: 'Permanently remove your account',
//             onTap: () => _navigateTo(context, '/delete-account'),
//             isDestructive: true,
//           ),
//         ],
//       ),
//       const SizedBox(height: 8),
//     ];
//   }
//
//   List<Widget> _buildGuestMenu(BuildContext context) {
//     return [
//       SizedBox(height: context.h(8)),
//       _buildSectionContainer(
//         context: context,
//         children: [
//           _buildMenuItem(
//             context,
//             icon: Icons.flight_takeoff,
//             title: 'Search Flights',
//             onTap: () => _navigateTo(context, '/search'),
//             subtitle: 'Find best deals',
//             isHighlighted: true,
//           ),
//         ],
//       ),
//       _buildSectionContainer(
//         context: context,
//         children: [
//           _buildMenuSection(context, 'EXPLORE'),
//           _buildMenuItem(
//             context,
//             icon: Icons.star_outline,
//             title: 'Travel Stories',
//             onTap: () => _navigateTo(context, '/stories'),
//           ),
//           _buildMenuItem(
//             context,
//             icon: Icons.article_outlined,
//             title: 'Upcoming Trips',
//             onTap: () => _navigateTo(context, '/trips'),
//           ),
//           _buildMenuItem(
//             context,
//             icon: Icons.currency_exchange,
//             title: 'Currency',
//             subtitle: CurrencyConverter.isAutoDetectEnabled()
//                 ? '$_currentCurrency (Auto - by location)'
//                 : _currentCurrency,
//             onTap: () => _showCurrencyPicker(context),
//           ),
//         ],
//       ),
//       _buildSectionContainer(
//         context: context,
//         children: [
//           _buildMenuSection(context, 'HELP'),
//           _buildMenuItem(
//             context,
//             icon: Icons.support_agent,
//             title: 'Contact Support',
//             onTap: () => _navigateTo(context, '/support'),
//           ),
//         ],
//       ),
//       SizedBox(height: context.h(8)),
//     ];
//   }
//
//   Widget _buildMenuSection(BuildContext context, String title) {
//     return Padding(
//       padding: EdgeInsets.only(
//         left: context.horizontalPadding.left,
//         top: context.gapLarge,
//         bottom: context.gapSmall,
//       ),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: context.labelMedium,
//           fontWeight: FontWeight.w700,
//           color: Colors.grey.shade500,
//           letterSpacing: 0.8,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMenuItem(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     String? subtitle,
//     Widget? trailing,
//     int? badgeCount,
//     bool isHighlighted = false,
//     bool isDestructive = false,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(context.r(12)),
//         child: Container(
//           margin: EdgeInsets.symmetric(
//             horizontal: context.horizontalPadding.left - context.w(4),
//             vertical: context.h(2),
//           ),
//           decoration: BoxDecoration(
//             color: isHighlighted
//                 ? Colors.blue.shade50.withOpacity(0.3)
//                 : Colors.transparent,
//             borderRadius: BorderRadius.circular(context.r(12)),
//           ),
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: context.horizontalPadding.left - context.w(8),
//               vertical: context.gapSmall,
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   icon,
//                   size: context.iconSmall,
//                   color: isDestructive
//                       ? Colors.red.shade400
//                       : isHighlighted
//                       ? Colors.blue.shade700
//                       : Colors.grey.shade700,
//                 ),
//                 SizedBox(width: context.gapMedium),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: TextStyle(
//                           fontSize: context.bodyMedium,
//                           fontWeight: isHighlighted
//                               ? FontWeight.w700
//                               : FontWeight.w500,
//                           color: isDestructive
//                               ? Colors.red.shade400
//                               : isHighlighted
//                               ? Colors.blue.shade700
//                               : Colors.black87,
//                         ),
//                       ),
//                       if (subtitle != null)
//                         Padding(
//                           padding: EdgeInsets.only(top: context.gapXSmall),
//                           child: Text(
//                             subtitle,
//                             style: TextStyle(
//                               fontSize: context.labelSmall,
//                               color: Colors.grey.shade500,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 if (badgeCount != null && badgeCount > 0)
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: context.w(6),
//                       vertical: context.h(2),
//                     ),
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [Colors.red, Colors.redAccent],
//                       ),
//                       borderRadius: BorderRadius.circular(context.r(10)),
//                     ),
//                     child: Text(
//                       '$badgeCount',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: context.labelSmall,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 if (trailing != null) trailing,
//                 Icon(
//                   Icons.chevron_right,
//                   size: context.iconSmall,
//                   color: Colors.grey.shade400,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDivider(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: context.horizontalPadding.left,
//         vertical: context.gapMedium,
//       ),
//       child: Divider(
//         color: Colors.grey.shade200,
//         thickness: context.h(1),
//         height: context.h(1),
//       ),
//     );
//   }
//
//   Widget _buildFooter(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(context.responsivePadding.right),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           top: BorderSide(color: Colors.grey.shade200, width: context.h(1)),
//         ),
//       ),
//       child: SafeArea(
//         top: false,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _isLoggedIn
//                 ? _buildLogoutButton(context)
//                 : _buildLoginButton(context),
//             SizedBox(height: context.gapSmall),
//             Center(
//               child: Text(
//                 _appVersion,
//                 style: TextStyle(
//                   fontSize: context.labelSmall,
//                   color: Colors.grey.shade400,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ),
//             SizedBox(height: context.gapSmall),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLogoutButton(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: context.w(4)),
//       decoration: BoxDecoration(
//         color: Colors.red.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(context.r(14)),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => _showLogoutDialog(context),
//           borderRadius: BorderRadius.circular(context.r(14)),
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: context.horizontalPadding.left,
//               vertical: context.gapMedium,
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(context.w(2)),
//                   decoration: BoxDecoration(
//                     color: Colors.red.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.logout_rounded,
//                     color: Colors.red,
//                     size: context.iconMedium,
//                   ),
//                 ),
//                 SizedBox(width: context.gapSmall),
//                 Flexible(
//                   child: Text(
//                     'Sign Out',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: context.bodyLarge,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoginButton(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: context.w(4)),
//       child: ElevatedButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             PageRouteBuilder(
//               opaque: false,
//               pageBuilder: (_, __, ___) => const LoginSignupScreen(),
//               transitionsBuilder: (_, animation, __, child) =>
//                   FadeTransition(opacity: animation, child: child),
//             ),
//           ).then((_) => _loadUserData());
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF0054A0),
//           foregroundColor: Colors.white,
//           minimumSize: Size(double.infinity, context.buttonHeight),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(context.r(14)),
//           ),
//           elevation: 0,
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.login_rounded, size: context.iconMedium),
//             SizedBox(width: context.gapSmall),
//             Flexible(
//               child: Text(
//                 'Login / Sign Up',
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize: context.bodyLarge,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             SizedBox(width: context.gapSmall),
//             Icon(Icons.arrow_forward_rounded, size: context.iconSmall),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _navigateTo(BuildContext context, String route) {
//     Navigator.pop(context);
//
//     Future.delayed(const Duration(milliseconds: 100), () {
//       switch (route) {
//         case '/dashboard':
//           Navigator.push(
//             context,
//             PageRouteBuilder(
//               pageBuilder: (context, animation, secondaryAnimation) =>
//                   DashboardScreen(userEmail: _userEmail, userName: _userName),
//               transitionsBuilder:
//                   (context, animation, secondaryAnimation, child) {
//                     return SlideTransition(
//                       position:
//                           Tween<Offset>(
//                             begin: const Offset(0.1, 0),
//                             end: Offset.zero,
//                           ).animate(
//                             CurvedAnimation(
//                               parent: animation,
//                               curve: Curves.easeOutCubic,
//                             ),
//                           ),
//                       child: FadeTransition(opacity: animation, child: child),
//                     );
//                   },
//               transitionDuration: const Duration(milliseconds: 500),
//             ),
//           );
//           break;
//         case '/payment':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => MakePaymentScreen()),
//           );
//           break;
//         case '/about':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => AboutUsScreen()),
//           );
//           break;
//         case '/delete-account':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
//           ).then((_) => _loadUserData());
//           break;
//         case '/bookings':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => MyBookingScreen()),
//           );
//           break;
//         case '/wallet_balance':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => WalletScreen()),
//           );
//           break;
//         case '/rewards':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const RewardsScreen()),
//           );
//           break;
//         case '/stories':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => AllTravelStoriesScreen()),
//           );
//           break;
//         case '/trips':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const UpcomingTripsScreen()),
//           );
//           break;
//         case '/profile':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => ProfileScreen()),
//           );
//           break;
//         case '/support':
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => SupportScreen()),
//           );
//           break;
//       }
//     });
//   }
//
//   /// Opens the currency screen (Figma `CHOOSE Currency`). It applies the
//   /// choice itself through CurrencyConverter and pops the saved code, so this
//   /// only has to mirror it into the drawer's own label.
//   Future<void> _showCurrencyPicker(BuildContext context) async {
//     final saved = await Navigator.push<String>(
//       context,
//       MaterialPageRoute(builder: (_) => const CurrencyScreen()),
//     );
//     if (saved != null && mounted) {
//       setState(() => _currentCurrency = saved);
//     }
//   }
//
//   void _showLogoutDialog(BuildContext context) {
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     Navigator.pop(context);
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         backgroundColor: Colors.white,
//         insetPadding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(24)),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(context.w(12)),
//         ),
//         child: Padding(
//           padding: EdgeInsets.fromLTRB(
//             context.w(22),
//             context.w(30),
//             context.w(22),
//             context.w(26),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 height: context.w(64),
//                 width: context.w(64),
//                 decoration: const BoxDecoration(
//                   color: AppColors.accent,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.logout_rounded,
//                   color: Colors.white,
//                   size: context.w(34),
//                 ),
//               ),
//               SizedBox(height: context.w(22)),
//               Text(
//                 'Logout?',
//                 style: TextStyle(
//                   fontSize: context.fs(20),
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.authInk,
//                 ),
//               ),
//               SizedBox(height: context.w(8)),
//               Text(
//                 'Are you sure, Do you want to Logout?',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: context.fs(12),
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.authSubtle,
//                 ),
//               ),
//               SizedBox(height: context.w(26)),
//               Row(
//                 children: [
//                   Expanded(
//                     child: SizedBox(
//                       height: context.w(46),
//                       child: OutlinedButton(
//                         onPressed: () => Navigator.pop(ctx),
//                         style: OutlinedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           side: const BorderSide(
//                             color: AppColors.OrangeColor,
//                             width: 1,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(context.w(12)),
//                           ),
//                         ),
//                         child: Text(
//                           'CANCEL',
//                           style: TextStyle(
//                             fontSize: context.fs(14),
//                             fontWeight: FontWeight.w600,
//                             letterSpacing: 0.4,
//                             color: AppColors.OrangeColor,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: context.w(14)),
//                   Expanded(
//                     child: SizedBox(
//                       height: context.w(46),
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.OrangeColor,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(context.w(12)),
//                           ),
//                         ),
//                         onPressed: () async {
//                           Navigator.pop(ctx);
//
//                           final logoutBloc = sl<LogoutBloc>();
//
//                           logoutBloc.stream
//                               .firstWhere(
//                                 (state) =>
//                                     state is LogoutSuccess ||
//                                     state is LogoutFailed,
//                               )
//                               .then((state) {
//                                 if (state is LogoutSuccess) {
//                                   print(
//                                     'Logout API successful: ${state.logoutEntity.message}',
//                                   );
//
//                                   SharedPreferences.getInstance().then((
//                                     prefs,
//                                   ) async {
//                                     final prefManager =
//                                         await PreferencesManager.create(prefs);
//                                     await prefManager.clearUserData();
//                                     await prefManager.clearAuth();
//
//                                     if (mounted) {
//                                       setState(() {
//                                         _isLoggedIn = false;
//                                         _userName = '';
//                                         _userEmail = '';
//                                         _userAvatar = null;
//                                       });
//                                     }
//                                   });
//                                   scaffoldMessenger.showSnackBar(
//                                     SnackBar(
//                                       content: Text('Logged Out Successfully'),
//                                       backgroundColor: Colors.red,
//                                     ),
//                                   );
//                                 } else if (state is LogoutFailed) {
//                                   print(
//                                     'Logout API failed: ${state.error.message}',
//                                   );
//                                   scaffoldMessenger.showSnackBar(
//                                     SnackBar(
//                                       content: Text(
//                                         'Logout failed Please try again',
//                                       ),
//                                       backgroundColor: Colors.red,
//                                     ),
//                                   );
//                                 }
//                               });
//
//                           logoutBloc.add(LogoutRequested());
//                         },
//                         child: Text(
//                           'LOGOUT',
//                           style: TextStyle(
//                             fontSize: context.fs(15),
//                             fontWeight: FontWeight.w600,
//                             letterSpacing: 0.4,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// >>>>>>> Stashed changes
