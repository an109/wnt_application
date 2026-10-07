import 'package:wander_nova/views/MyBookings/Screen/MyBooking_Screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/currency_chip.dart';
import 'package:wander_nova/common_widgets/custom_drawer.dart';
import 'package:wander_nova/common_widgets/fast_network_image_cache_manager.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/views/home/presentation/screens/searchSection.dart';
import '../../../../injection_container.dart';
import '../../../../newUIWidgets/Home_nav.dart';
import '../../../TrishaAI/presentation/screen/trisha_chat_screen.dart';
import '../../../Holidays/presentation/screen/holidays_screen.dart';
import '../../../Hotel/screen/hotel_screen.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../Transport/screen/transport_screen.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_bloc.dart';
import '../../../ExclusiveDeals/presentation/bloc/exclusive_deals_event.dart';
import '../../../flight_popularDestination/presentation/bloc/destination_bloc.dart';
import '../../../flight_popularDestination/presentation/bloc/destination_event.dart';
import '../../../notifications/notifications_screen.dart';
import '../../../travel_stories/presentation/bloc/travel_stories_bloc.dart';
import '../../../travel_stories/presentation/bloc/travel_stories_event.dart';
import '../../../trending_route/presentation/bloc/trending_routes_bloc.dart';
import '../../../trending_route/presentation/bloc/trending_routes_event.dart';
import '../../../visa/presentation/screen/visa_screen.dart';
import '../../../AKInsurance/presentation/screens/ins_home_screen.dart';
import '../../flight/flight_screen.dart';
import '../../../offers/offers_screen.dart';
import '../widgets/home_sections.dart';
import '../widgets/home_top_widgets.dart';

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
  bool _startVoiceSearch = false;

  // ---------------------------------------------------------------------
  // Scroll-based expand/pin for the hero's search bar: once the hero's own
  // top bar scrolls out of view, a full-width search bar fades/slides in
  // pinned to the very top of the screen; scrolling back near the top
  // reverts to the normal hero layout (drawer + search + currency + bell).
  // Purely additive/visual — the hero's own top bar is never modified.
  // ---------------------------------------------------------------------
  bool _showFloatingSearchBar = false;

  @override
  void initState() {
    super.initState();
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
      value: SystemUiOverlayStyle.dark,
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
                    // Trip — the home tab stays selected underneath.
                    setState(() => selectedNavIndex = 0);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyBookingScreen()),
                    );
                  } else if (index == 2) {
                    // Offer — the home tab stays selected underneath.
                    setState(() => selectedNavIndex = 0);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OffersScreen()),
                    );
                  } else if (index == 3) {
                    // Wishlist
                  }
                },
                onCenterTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrishaChatScreen()),
                  );
                },
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                context.read<GeneralSettingsBloc>().add(
                  const LoadGeneralSettings(domain: 'thewandernova.com'),
                );
                context.read<ExclusiveDealsBloc>().add(
                  const LoadExclusiveDeals(),
                );
                context.read<PopularDestinationBloc>().add(
                  const FetchPopularDestinations(),
                );
                context.read<TrendingRoutesBloc>().add(
                  const RefreshTrendingRoutes(domain: 'thewandernova.com'),
                );
                context.read<TravelStoriesBloc>().add(
                  const GetTravelStoriesEvent(
                    status: 'published',
                    domain: 'thewandernova.com',
                    limit: 8,
                  ),
                );
                _loadRecentSearches();

                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: const Color(0xff005B7F),
              backgroundColor: Colors.white,
              child: Container(
                color: Colors.white,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: context.scrollPhysics,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildTopSection(context)
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: -0.04),
                    ),
                    // Everything below the top section is built lazily (only as it
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
              startWithVoice: _startVoiceSearch,
              onHide: () {
                setState(() {
                  _showSlidingSearch = false;
                  _startVoiceSearch = false;
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
  // Lazily-built sections below the top section, in Figma order. Every
  // section is separated by the same 44px gap.
  // =========================================================================
  static const List<Widget> _sections = [
    HomePopularDestinations(),
    HomeTravelRoutes(),
    HomeStaySection(),
    HomeTravelStories(),
  ];

  // Sections plus the gaps between them, then the footer.
  static int get _sectionCount => _sections.length * 2;

  Widget _buildSection(int index) {
    if (index == _sectionCount - 1) return const HomeFooter();
    if (index.isOdd) return SizedBox(height: context.fx(44));
    return _sections[index ~/ 2];
    // Offers ("HOT DEAL / FLIGHT / HOTEL…") isn't part of the new design:
    // BlocProvider<ExclusiveDealsBloc>(
    //   create: (context) => sl<ExclusiveDealsBloc>(),
    //   child: const TransportExclusiveDealsSection(),
    // ),
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
                context.fx(16),
                topInset + context.fx(12),
                context.fx(16),
                context.fx(12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
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
  // Top section: menu / currency / bell, search, the info carousel, the
  // service grid and the sponsored banner.
  // =========================================================================

  Widget _buildTopSection(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.fx(16),
        topInset + context.fx(16),
        context.fx(16),
        0,
      ),
      child: Column(
        children: [
          _buildTopBar(context),
          SizedBox(height: context.fx(28)),
          _buildSearchBar(context),
          SizedBox(height: context.fx(26)),
          // Offers from the backend, shown in the info-banner design.
          const HomeOffersCarousel(),
          SizedBox(height: context.fx(44)),
          _buildServiceIconGrid(context),
          SizedBox(height: context.fx(45)),
          HomeAdBanner(
            onExplore: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HolidaysScreen()),
            ),
          ),
          SizedBox(height: context.fx(44)),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: SvgPicture.asset(
            'assets/home/menu.svg',
            width: context.fx(24),
            height: context.fx(24),
          ),
        ),
        const Spacer(),
        const CurrencyChip(),
        SizedBox(width: context.fx(16)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: SvgPicture.asset(
            'assets/home/notification.svg',
            width: context.fx(24),
            height: context.fx(24),
          ),
        ),
      ],
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
        padding: EdgeInsets.symmetric(
          horizontal: context.fx(16),
          vertical: context.fx(12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(context.fx(24)),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/Newgif/search.gif',
                width: context.fx(24),
                height: context.fx(24),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: context.fx(8)),
            Expanded(
              child: Text(
                'Search places',
                style: TextStyle(
                  color: const Color(0xFF757575),
                  fontSize: context.ffs(10),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _startVoiceSearch = true;
                  _showSlidingSearch = true;
                });
                SystemChannels.textInput.invokeMethod('TextInput.hide');
              },
              child: SvgPicture.asset(
                'assets/home/mic.svg',
                width: context.fx(24),
                height: context.fx(24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIconGrid(BuildContext context) {
    Widget row(List<_HomeService> services) => Row(
      children: [
        for (var i = 0; i < services.length; i++) ...[
          if (i > 0) SizedBox(width: context.fx(16)),
          Expanded(child: _buildServiceCard(context, services[i])),
        ],
      ],
    );

    return Column(
      children: [
        row(_HomeService.all.sublist(0, 3)),
        SizedBox(height: context.fx(16)),
        row(_HomeService.all.sublist(3)),
      ],
    );
  }

  void _openService(BuildContext context, String label) {
    final Widget screen;
    switch (label) {
      case 'Flight':
        screen = const FlightScreen();
      case 'Hotel':
        screen = const HotelBookingScreen();
      case 'Holiday':
        screen = const HolidaysScreen();
      case 'Visa':
        screen = VisaScreen();
      case 'Transfers':
        screen = const TransportBookingScreen();
      case 'Insurance':
        screen = const InsHomeScreen();
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildServiceCard(BuildContext context, _HomeService service) {
    return GestureDetector(
      onTap: () => _openService(context, service.label),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.fx(6),
          vertical: context.fx(8),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.fx(8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HomeCroppedImage(
              asset: service.sprite,
              width: service.iconWidth,
              height: service.iconHeight,
              imageWidthFactor: service.imageWidthFactor,
              imageHeightFactor: service.imageHeightFactor,
              leftFactor: service.leftFactor,
              topFactor: service.topFactor,
            ),
            SizedBox(height: context.fx(4)),
            Text(
              service.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: context.ffs(14),
                fontWeight: FontWeight.w700,
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

/// A service tile on the home grid. The icons are crops of the two Figma
/// sprite sheets, positioned exactly as the design's image fills are.
class _HomeService {
  final String label;
  final String sprite;
  final double iconWidth;
  final double iconHeight;
  final double imageWidthFactor;
  final double imageHeightFactor;
  final double leftFactor;
  final double topFactor;

  const _HomeService(
    this.label,
    this.sprite,
    this.iconWidth,
    this.iconHeight,
    this.imageWidthFactor,
    this.imageHeightFactor,
    this.leftFactor,
    this.topFactor,
  );

  static const _row1 = 'assets/home/services_row1.png';
  static const _row2 = 'assets/home/services_row2.png';

  static const all = [
    _HomeService('Flight', _row1, 34, 34, 5.0895, 1.6941, -0.1469, -0.3765),
    _HomeService('Hotel', _row1, 34, 34, 5.0895, 1.6941, -1.4116, -0.3471),
    _HomeService('Holiday', _row1, 34, 34, 5.0895, 1.6941, -2.6175, -0.4059),
    _HomeService('Visa', _row2, 34, 35, 3.9512, 1.2857, -0.1951, -0.2143),
    _HomeService('Transfers', _row2, 40, 35, 3.3585, 1.2857, -2.2909, -0.2143),
    _HomeService('Insurance', _row2, 34, 35, 3.9512, 1.2857, -1.3422, -0.2143),
  ];
}
