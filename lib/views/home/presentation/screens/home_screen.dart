import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/custom_drawer.dart';
import 'package:wander_nova/common_widgets/fast_network_image_cache_manager.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/views/home/presentation/screens/searchSection.dart';
import '../../../../injection_container.dart';
import '../../../../newUIWidgets/Home_nav.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';
import '../../../ExclusiveDeals/presentation/screen/T_exclusiveDeals.dart';
import '../../../Holidays/presentation/screen/holidays_screen.dart';
import '../../../Hotel/screen/hotel_screen.dart';
import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../NewSection/CompanyInfo.dart';
import '../../../NewSection/NewSection.dart';
import '../../../NewSection/foryourStay.dart';
import '../../../Transport/screen/transport_screen.dart';
import '../../../travel_stories/presentation/screen/travel_stories.dart';
import '../../../visa/presentation/screen/visa_screen.dart';
import '../../../Insurance/insurance_screen.dart';
import '../../../flight_popularDestination/presentation/screen/popular_destination.dart';
import '../../../trending_route/presentation/screen/trending_routes.dart';
import '../../flight/flight_screen.dart';

/// Remembers the hero banner URL the General Settings API last returned and
/// keeps it warm in the image caches.
///
/// The hero photo is a remote image whose URL is only known *after* the
/// General Settings call comes back, so a cold home screen used to sit on the
/// plain gradient for API-latency + download time before the photo appeared.
/// Persisting the last URL lets the screen start fetching the (already
/// disk-cached) photo on its very first frame, in parallel with that API call
/// rather than after it, and [warmUp] pushes the decode even earlier — onto
/// the splash screen — so the photo is in the memory cache by the time the
/// home screen builds. The API response still wins whenever it differs; this
/// only removes the wait when it doesn't.
class HomeHeroBanner {
  const HomeHeroBanner._();

  static const String _prefsKey = 'home_hero_banner_url';

  /// The banner URL from the last successful General Settings load, if any.
  static String? get lastKnownUrl {
    try {
      final url = sl<PreferencesManager>().getString(_prefsKey);
      return (url != null && url.trim().isNotEmpty) ? url.trim() : null;
    } catch (_) {
      return null;
    }
  }

  static void remember(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == lastKnownUrl) return;
    try {
      sl<PreferencesManager>().setString(_prefsKey, trimmed);
    } catch (_) {
      // Persisting is a pure optimisation — never let it break the screen.
    }
  }

  /// Decoded-bitmap width to request for the hero. The photo is full-bleed,
  /// so the screen's physical pixel width is exactly what's needed — decoding
  /// the source at its native (often multi-thousand pixel) width would cost
  /// time and memory for pixels that can never be shown.
  static int decodeWidthFor(BuildContext context) {
    final logicalWidth = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalWidth * dpr).round().clamp(320, 2160);
  }

  /// The exact provider the hero renders with, so a [warmUp] hit also lands
  /// in Flutter's in-memory image cache and not just on disk.
  static ImageProvider providerFor(BuildContext context, String url) {
    return ResizeImage.resizeIfNeeded(
      decodeWidthFor(context),
      null,
      CachedNetworkImageProvider(
        url,
        cacheManager: FastNetworkImageCacheManager.instance,
      ),
    );
  }

  /// Fire-and-forget pre-decode of the remembered banner. Safe to call from
  /// anywhere with a context (the splash screen does); a miss, a failure or a
  /// missing URL all no-op.
  static void warmUp(BuildContext context) {
    final url = lastKnownUrl;
    if (url == null) return;
    try {
      precacheImage(providerFor(context, url), context, onError: (_, __) {});
    } catch (_) {
      // Warm-up is best effort only.
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int selectedNavIndex = 0;
  List<Map<String, dynamic>> _recentSearches = [];

  // ---------------------------------------------------------------------
  // Scroll-based hide/show for the bottom nav: scrolling down slides it
  // out of view, scrolling up (or being back near the top) brings it back.
  // ---------------------------------------------------------------------
  final ScrollController _scrollController = ScrollController();
  bool _bottomNavVisible = true;
  double _lastScrollOffset = 0;
  bool _showSlidingSearch = false;

  // ---------------------------------------------------------------------
  // Scroll-based expand/pin for the hero's search bar: once the hero's own
  // top bar scrolls out of view, a full-width search bar fades/slides in
  // pinned to the very top of the screen; scrolling back near the top
  // reverts to the normal hero layout (drawer + search + currency + bell).
  // Purely additive/visual — the hero's own top bar is never modified.
  // ---------------------------------------------------------------------
  bool _showFloatingSearchBar = false;

  /// Banner URL remembered from the previous run, used to paint the hero
  /// photo immediately while the General Settings call that supplies the
  /// authoritative URL is still in flight. See [HomeHeroBanner].
  String? _cachedHeroBannerUrl;

  @override
  void initState() {
    super.initState();
    _cachedHeroBannerUrl = HomeHeroBanner.lastKnownUrl;
    _loadRecentSearches();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    _updateFloatingSearchBar(offset);

    // Always reveal the nav bar once the user is back near the top.
    if (offset <= 8 && !_bottomNavVisible) {
      setState(() => _bottomNavVisible = true);
      return;
    }
    if (delta > 6 && _bottomNavVisible) {
      setState(() => _bottomNavVisible = false);
    } else if (delta < -6 && !_bottomNavVisible) {
      setState(() => _bottomNavVisible = true);
    }
  }

  // Hysteresis so the floating search bar doesn't flicker in/out right at
  // the threshold — it appears once the hero's own top bar has scrolled
  // out of view, and disappears again once we're back near the very top.
  void _updateFloatingSearchBar(double offset) {
    const showAt = 190.0;
    const hideAt = 130.0;
    if (offset > showAt && !_showFloatingSearchBar) {
      setState(() => _showFloatingSearchBar = true);
    } else if (offset <= hideAt && _showFloatingSearchBar) {
      setState(() => _showFloatingSearchBar = false);
    }
  }

  // ---------------------------------------------------------------------
  // Recent searches — unchanged from the previous implementation.
  // ---------------------------------------------------------------------
  Future<void> _loadRecentSearches() async {
    try {
      final prefsManager = await PreferencesManager.create(
        await SharedPreferences.getInstance(),
      );
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
        } else if (type == 'holiday') {
          final destId = (item['destination']?['id'] ?? '').toString();
          if (destId.isEmpty) continue;
          key = 'holiday-$destId';
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        drawer: const CustomDrawer(),
        onDrawerChanged: (isOpened) {
          // Drawer login/logout/delete-account actions can switch the active
          // user; refresh once it closes so Recent Searches reflects whoever
          // is signed in now instead of stale data from before.
          if (!isOpened) _loadRecentSearches();
        },
        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          offset: _bottomNavVisible ? Offset.zero : const Offset(0, 1.3),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: context.h(12)),
              child: CustomBottomNav(
                currentIndex: selectedNavIndex,
                onItemSelected: (index) {
                  setState(() {
                    selectedNavIndex = index;
                  });

                  // Navigation logic
                  if (index == 0) {
                    // Home
                  } else if (index == 1) {
                    // Trip
                  } else if (index == 2) {
                    // Booking
                  } else if (index == 3) {
                    // Offer
                  }
                },
                onCenterTap: () {
                  // Center GIF button action
                  debugPrint("AI button clicked");
                },
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                final generalBloc = context.read<GeneralSettingsBloc>();
                final dealsBloc = context.read<ExclusiveDealsBloc>();

                // generalBloc.add(
                //   const LoadFaqList(domain: 'thewandernova.com'),
                // );
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
                color: const Color(0xFFFFFFFF),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: context.scrollPhysics,
                  slivers: [
                    // Full-bleed hero — no side padding, matches the Figma reference.
                    SliverToBoxAdapter(
                      child: _buildHeroCard(context)
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: -0.08),
                    ),
                    // SliverToBoxAdapter(
                    //   child: Padding(
                    //     padding: EdgeInsets.symmetric(horizontal: context.w(10)),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         SizedBox(height: context.h(20)),
                    //         _buildRecentSearchesSection(context),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    // Everything below the hero is built lazily (only as it
                    // scrolls near the viewport) instead of all at once, so
                    // the first frame doesn't have to build + kick off the
                    // network calls of every section simultaneously. Each
                    // section is kept alive once built so scrolling away and
                    // back never re-triggers its fetch or loses its state —
                    // identical behaviour to before, just spread out over
                    // time instead of paid for up front.
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _KeepAliveWrapper(child: _buildSection(index)),
                        childCount: _sectionCount,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showSlidingSearch)
              Positioned.fill(
                child: SlidingSearchSection(
                  isVisible: _showSlidingSearch,
                  onHide: () {
                    setState(() {
                      _showSlidingSearch = false;
                    });
                  },
                ),
              ),
            SlidingSearchSection(
              isVisible: _showSlidingSearch,
              onHide: () {
                setState(() {
                  _showSlidingSearch = false;
                });
              },
            ),

            _buildFloatingSearchBar(context),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Lazily-built sections below the hero. Index order matches the previous
  // fixed sliver list exactly, so visual layout/spacing is unchanged.
  // =========================================================================
  static const int _sectionCount = 11;

  Widget _buildSection(int index) {
    switch (index) {
      case 0:
        return BlocProvider<ExclusiveDealsBloc>(
          create: (context) => sl<ExclusiveDealsBloc>(),
          child: const TransportExclusiveDealsSection(),
        );
      case 1:
        return const SizedBox(height: 20);
      case 2:
        return const PopularDestinations();
      case 3:
        return const SizedBox(height: 15);
      case 4:
        return const TrendingPackages();
      case 5:
        return const SizedBox(height: 8);
      // case 5:
      //   return const ForYourStaySection();
      // case 6:
      //   return const SizedBox(height: 20);
      case 5:
        return const TravelStoriesSection();
      // case 8:
      //   return const WhyWanderNovaSection();
      // case 9:
      //   return const SizedBox(height: 20);
      // case 10:
      //   return const CompanyInformationSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFloatingSearchBar(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        // Disable the floating search while the sliding panel is open.
        ignoring: !_showFloatingSearchBar || _showSlidingSearch,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,

          // First move out when sliding search opens.
          // Second move out when the floating search itself is hidden.
          offset: (_showFloatingSearchBar && !_showSlidingSearch)
              ? Offset.zero
              : const Offset(0, -1),

          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,

            opacity: (_showFloatingSearchBar && !_showSlidingSearch)
                ? 1.0
                : 0.0,

            child: Container(
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                topInset + context.h(16),
                context.w(20),
                context.h(16),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF003B95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: context.w(8),
                    offset: Offset(0, context.h(2)),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  // Open the top sliding search.
                  setState(() {
                    _showSlidingSearch = true;
                  });
                },
                child: _buildSearchBar(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================

  // =========================================================================

  Widget _buildHeroCard(BuildContext context) {
    return BlocProvider<GeneralSettingsBloc>(
      create: (_) =>
          sl<GeneralSettingsBloc>()
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
          if (bannerUrl != null) {
            // Next cold start can begin fetching this photo on frame one
            // instead of waiting for the API to name it again.
            HomeHeroBanner.remember(bannerUrl);
            _cachedHeroBannerUrl = bannerUrl;
          }
          // Until the API answers, show the URL the previous run ended on —
          // it's already in the disk cache, so it paints straight away.
          return _buildHeroCardContent(
            context,
            bannerUrl ?? _cachedHeroBannerUrl,
          );
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
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      height: context.h(400), // Slightly taller for better gradient visibility
      child: Stack(
        children: [
          Positioned.fill(child: _buildHeroBackground(context, bannerUrl)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              topInset + context.h(16),
              context.w(16),
              context.h(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.h(16)),
                _buildTopBar(context),
                SizedBox(height: context.h(74)),
                Expanded(child: _buildServiceIconGrid(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBackground(BuildContext context, String? bannerUrl) {
    const brandGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF003B95), Color(0xFF005B7F)],
    );

    if (bannerUrl == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(gradient: brandGradient),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient
        const DecoratedBox(decoration: BoxDecoration(gradient: brandGradient)),

        // Hero Image — cached to disk so repeat launches paint it from
        // local storage instead of re-downloading, and decoded no wider
        // than the screen so a large source photo doesn't stall the first
        // frames. While it loads the brand gradient below stays visible,
        // exactly as before.
        CachedNetworkImage(
          imageUrl: bannerUrl,
          cacheManager: FastNetworkImageCacheManager.instance,
          fit: BoxFit.cover,
          memCacheWidth: HomeHeroBanner.decodeWidthFor(context),
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (_, __) => const SizedBox.shrink(),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        ),

        // ====== LAYER GRADIENT EFFECT (NO BLUR) ======
        // Layer 1: Soft white gradient that creates the "cloudy" look
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(154),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.92),
                  Colors.white.withOpacity(0.72),
                  Colors.white.withOpacity(0.38),
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.20, 0.40, 0.60, 0.80, 1.0],
              ),
            ),
          ),
        ),

        // Layer 2: Additional subtle gradient overlay for depth
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: context.h(100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Top scrim for text readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.20),
                Colors.black.withOpacity(0.10),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        // Drawer icon
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Image.asset(
            'assets/NewIcons/drawerHD.png',
            width: context.w(20),
            height: context.w(20),
            color: Colors.white,
          ),
        ),
        SizedBox(width: context.w(12)),
        // Search bar
        Expanded(child: _buildSearchBar(context)),
        SizedBox(width: context.w(12)),
        // Currency chip
        _buildCurrencyChip(context),
        SizedBox(width: context.w(12)),
        // Notification icon
        GestureDetector(
          onTap: () {},
          child: Image.asset(
            'assets/NewIcons/notificationHD.png', // or bell.png
            width: context.w(20),
            height: context.w(20),
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(context.w(9)),
          child: Icon(icon, color: Colors.white, size: context.iconMedium),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSlidingSearch = true;
        });
        // Hide keyboard if open
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      child: Container(
        height: context.h(37),
        padding: EdgeInsets.symmetric(horizontal: context.w(16)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(context.r(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: context.w(8),
              offset: Offset(0, context.h(2)),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/Newgif/search.gif',
                width: context.w(18),
                height: context.w(18),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Text(
                'Search places',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: context.w(8)),
            Image.asset(
              'assets/NewIcons/micHD.png',
              width: context.w(14),
              height: context.w(14),
              color: AppColors.AppBlue,
            ),
          ],
        ),
      ),
    );
  }

  /// Static display of the saved preferred currency — not an interactive
  /// picker. Rebuilds on `CurrencyConverter.currencyListenable` so both the
  /// flag and the symbol follow whatever the user picks in the drawer's
  /// currency setting, without waiting for a fresh navigation to the screen.
  Widget _buildCurrencyChip(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: CurrencyConverter.currencyListenable,
      builder: (context, currency, _) {
        final symbol = CurrencyConverter.getSymbol(currency);
        final flag = CurrencyConverter.getFlag(currency);

        return Container(
          height: context.h(37),
          padding: EdgeInsets.symmetric(horizontal: context.w(10)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(context.r(6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: TextStyle(fontSize: context.fs(14))),
              SizedBox(width: context.w(4)),
              Text(
                symbol,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: context.bodySmall,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceIconGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildHeroServiceIcon(
                context,
                'Flight',
                'assets/NewIcons/HFlight.png',
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: _buildHeroServiceIcon(
                context,
                'Hotels',
                'assets/NewIcons/hotel.png',
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: _buildHeroServiceIcon(
                context,
                'Holiday',
                'assets/NewIcons/holidays.png',
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(10)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildHeroServiceIcon(
                context,
                'Visa',
                'assets/NewIcons/visa.png',
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: _buildHeroServiceIcon(
                context,
                'Transport',
                'assets/NewIcons/transport.png',
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: _buildHeroServiceIcon(
                context,
                'Insurance',
                'assets/NewIcons/insurance.png',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroServiceIcon(
    BuildContext context,
    String label,
    String assetPath,
  ) {
    VoidCallback? onTap;

    switch (label) {
      case 'Flight':
        onTap = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlightScreen()),
        );
        break;
      case 'Hotels':
        onTap = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelBookingScreen()),
        );
        break;
      case 'Holiday':
        onTap = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HolidaysScreen()),
        );
        break;
      case 'Visa':
        onTap = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VisaScreen()),
        );
        break;
      case 'Transport':
        onTap = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransportBookingScreen()),
        );
        break;
      case 'Insurance':
        onTap = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InsuranceScreen()),
        );
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.w(6)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(color: Colors.white.withOpacity(0.50), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: context.w(6),
              offset: Offset(0, context.h(2)),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: context.h(37),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.r(6)),
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  width: context.w(27),
                  height: context.w(27),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: context.h(6)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: context.fs(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Recent Searches — unchanged from the previous implementation.
  // =========================================================================

  Widget _buildRecentSearchCard(
    BuildContext context,
    Map<String, dynamic> search,
  ) {
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
    } else if (type == 'holiday') {
      typeLabel = 'Holiday';
      final dest = search['destination'];
      primaryLine = (dest?['name'] ?? '').toString();
      final city = (dest?['city'] ?? '').toString();
      final country = (dest?['country'] ?? '').toString();
      secondaryLine = [city, country].where((s) => s.isNotEmpty).join(', ');
      date = _formatSearchDate(search['departureDate']);
    } else if (type == 'transport') {
      typeLabel = 'Cab';
      final pickup = search['pickup'];
      final dropoff = search['dropoff'];
      final pickupName =
          (pickup?['city'] ?? pickup?['label'] ?? pickup?['name'] ?? '')
              .toString();
      final dropoffName =
          (dropoff?['city'] ?? dropoff?['label'] ?? dropoff?['name'] ?? '')
              .toString();
      primaryLine = pickupName;
      secondaryLine = dropoffName;
      date = _formatSearchDate(search['pickupDate']);
    } else {
      typeLabel = 'Flight';
      final from = search['fromAirport'];
      final to = search['toAirport'];
      final fromCity = (from?['city'] ?? '').toString();
      final toCity = (to?['city'] ?? '').toString();
      primaryLine =
          '${(from?['code'] ?? '').toString()}  →  ${(to?['code'] ?? '').toString()}';
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

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
