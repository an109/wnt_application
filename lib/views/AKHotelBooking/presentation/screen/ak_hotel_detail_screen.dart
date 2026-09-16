import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../AKHotelDetailContent/domain/entity/AKHotelDetailContent_entity.dart';
import '../../../AKHotelDetailContent/domain/usecase/AKHotelDetailContent_usecase.dart';
import '../../../AKHotelRooms/domain/entity/AKHotelRooms_entity.dart';
import '../../../AKHotelRooms/domain/usecase/AKHotelRooms_usecase.dart';
import '../../../AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import '../widgets/ak_hotel_image_carousel.dart';
import 'ak_hotel_amenities_screen.dart';
import 'ak_hotel_photo_gallery_screen.dart';
import 'ak_hotel_price_confirm_screen.dart';
import 'ak_hotel_property_rules_screen.dart';
import 'ak_hotel_review_screen.dart';
import 'ak_hotel_room_options_screen.dart';

/// Hotel detail page: static Content (images, address, policies, geoCode)
/// and Rooms (bookable options) are independent calls, fetched in parallel —
/// same "fire both, don't wait on one for the other" contract as the
/// results screen's Content+Rate. [_roomsFuture] is the *single* Rooms call
/// this screen ever makes; it's handed as-is to [AkHotelRoomOptionsScreen]
/// when "SELECT ROOM" is tapped, so that screen never re-fetches.
///
/// Layout is one continuous scroll (Figma reference): a collapsing photo
/// hero, an overlapping thumbnail strip (tap → [AkHotelPhotoGalleryScreen],
/// reusing the same [PhotoGallerySection] the old "Photos" tab used), then
/// Overview/Location/Reviews/About/Property Rules sections in order, with a
/// pinned tab row that scrolls to whichever section is tapped — except
/// "Amenities", which opens [AkHotelAmenitiesScreen] as its own screen
/// instead of an inline section. The "Rooms" tab from the old tabbed
/// layout no longer lives inline either — it's now
/// [AkHotelRoomOptionsScreen], reached via the bottom bar.
class AkHotelDetailScreen extends StatefulWidget {
  final String searchId;
  final String searchTracingKey;
  final String hotelId;
  final String hotelName;
  final String priceProvider;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final String nationality;

  /// The exact per-room adults/children/childAges the user searched with —
  /// see [AkHotelResultsScreen.rooms] for why this is threaded through
  /// rather than re-derived from the Rooms API response.
  final List<AkHotelSearchInitRoomEntity> rooms;

  const AkHotelDetailScreen({
    super.key,
    required this.searchId,
    required this.searchTracingKey,
    required this.hotelId,
    required this.hotelName,
    required this.priceProvider,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.nationality,
    required this.rooms,
  });

  @override
  State<AkHotelDetailScreen> createState() => _AkHotelDetailScreenState();
}

class _DetailTab {
  final String label;
  final GlobalKey key;
  _DetailTab(this.label, this.key);
}

class _AkHotelDetailScreenState extends State<AkHotelDetailScreen> {
  static const _blue = AppColors.AppBlue;
  static const _navy = AppColors.black;
  static const _border = AppColors.lightsubhead;
  static const _muted = AppColors.subhead;

  final ScrollController _scrollController = ScrollController();
  bool _collapsed = false;
  bool _favorite = false;

  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _amenitiesKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _reviewsKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _rulesKey = GlobalKey();

  /// Recomputed on every access (not fixed at construction) so a tab for a
  /// section with nothing real to show — no amenities/attractions, no
  /// rating — disappears the moment Content resolves, instead of jumping
  /// to an empty section.
  List<_DetailTab> get _tabs {
    final c = _content;
    final hasAmenities =
        (c?.facilities.isNotEmpty ?? false) ||
        (c?.nearByAttractions.isNotEmpty ?? false);
    final hasRating = ((c?.reviewRating ?? 0) > 0 && (c?.reviewCount ?? 0) > 0) || (c?.starRating ?? 0) > 0;
    return [
      _DetailTab('Overview', _overviewKey),
      if (hasAmenities) _DetailTab('Amenities', _amenitiesKey),
      _DetailTab('Location', _locationKey),
      if (hasRating) _DetailTab('Reviews', _reviewsKey),
      _DetailTab('About', _aboutKey),
      _DetailTab('Property Rules', _rulesKey),
    ];
  }

  int _activeTabIndex = 0;

  AkHotelDetailContentEntity? _content;
  /// True until [_loadContent] resolves (success or failure) — gates the
  /// full-page shimmer. Kept separate from `_content == null` so a failed
  /// call falls through to the normal (empty-state) layout instead of an
  /// infinite shimmer.
  bool _contentLoading = true;
  late final Future<DataState<AkHotelRoomsResultEntity>> _roomsFuture;

  double? _distanceKm;
  bool _locating = false;
  String? _locationError;

  /// Height of the hero image itself.
  double get _heroHeight => context.hp(38);

  /// Fixed height of the photo strip card. Kept as a getter so both the
  /// hero layout and the strip builder use the same number.
  double get _stripCardHeight => context.h(76);

  /// How far the strip dips below the hero image's bottom edge. Since we
  /// center the strip on the image's bottom edge, this equals half the
  /// strip height.
  double get _stripOverlap => _stripCardHeight / 2;

  /// Total app-bar height: hero image + space for the strip to hang below.
  /// The extra `_stripOverlap` is transparent/white, so it visually blends
  /// with the content area below — the strip "hangs off" the hero.
  double get _appBarHeight => _heroHeight + _stripOverlap;

  double get _tabBarHeight => context.h(52);

  @override
  void initState() {
    super.initState();
    _loadContent();
    _roomsFuture = sl<AkHotelRoomsUseCase>().call(
      AkHotelRoomsRequestEntity(
        searchId: widget.searchId,
        hotelId: widget.hotelId,
        searchTracingKey: widget.searchTracingKey,
      ),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Collapse once the hero image itself (not the extra strip room) has
    // scrolled past the toolbar.
    final shouldCollapse =
        _scrollController.offset >
        (_heroHeight - kToolbarHeight - context.h(10));
    if (shouldCollapse != _collapsed) {
      setState(() => _collapsed = shouldCollapse);
    }
  }

  Future<void> _loadContent() async {
    final result = await sl<AkHotelDetailContentUseCase>().call(
      AkHotelDetailContentRequestEntity(
        searchId: widget.searchId,
        hotelId: widget.hotelId,
        priceProvider: widget.priceProvider,
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result is DataSuccess<AkHotelDetailContentEntity>)
        _content = result.data;
      _contentLoading = false;
    });
    // Auto-compute the distance as soon as we have somewhere to compute it
    // to — the user shouldn't have to tap anything to see it under the
    // address. `_useMyLocation` still no-ops gracefully (shows a retry
    // link) if permission is denied.
    if (_content?.lat != null && _content?.long != null) {
      _useMyLocation();
    }
  }

  /// Requests location permission (if needed) and the device's current
  /// position, then computes the real straight-line distance to the hotel's
  /// own `lat`/`long` from Content — never a hardcoded location.
  Future<void> _useMyLocation() async {
    final c = _content;
    if (c?.lat == null || c?.long == null) return;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are turned off.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission was denied.';
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        c!.lat!,
        c.long!,
      );
      if (!mounted) return;
      setState(() {
        _distanceKm = meters / 1000;
        _locating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e is String ? e : 'Could not detect your location.';
        _locating = false;
      });
    }
  }

  void _selectRoom(
    AkHotelRecommendationEntity recommendation,
    AkHotelRoomGroupEntity roomGroup,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelPriceConfirmScreen(
          searchId: widget.searchId,
          searchTracingKey: widget.searchTracingKey,
          hotelId: widget.hotelId,
          hotelName: widget.hotelName,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          recommendationId: recommendation.id,
          roomGroup: roomGroup,
          nationality: widget.nationality,
          rooms: widget.rooms,
        ),
      ),
    );
  }

  void _openRoomOptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelRoomOptionsScreen(
          hotelName: widget.hotelName,
          roomsFuture: _roomsFuture,
          onSelectRoom: _selectRoom,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          adults: widget.adults,
          children: widget.children,
          content: _content,
        ),
      ),
    );
  }

  void _openPhotoGallery() {
    if (_images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelPhotoGalleryScreen(
          images: _images,
          hotelName: widget.hotelName,
          rating: (_content?.starRating ?? 0).round(),
        ),
      ),
    );
  }

  void _openAmenitiesScreen() {
    final facilities = _content?.facilities ?? const <String>[];
    if (facilities.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelAmenitiesScreen(hotelName: widget.hotelName, facilities: facilities),
      ),
    );
  }

  void _shareHotel() {
    Share.share('Check out ${widget.hotelName}!');
  }

  void _scrollToTab(int index) {
    if (index < 0) return;
    // Amenities is its own full screen (see [AkHotelAmenitiesScreen]), not
    // an inline section to scroll to.
    if (_tabs[index].label == 'Amenities') {
      _openAmenitiesScreen();
      return;
    }
    setState(() => _activeTabIndex = index);
    if (index == 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }
    final renderObject = _tabs[index].key.currentContext?.findRenderObject();
    if (renderObject == null) return;
    final viewport = RenderAbstractViewport.of(renderObject);
    final revealOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
    final target = (revealOffset - kToolbarHeight - _tabBarHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  List<String> get _images {
    final c = _content;
    if (c == null) return const [];
    final all = <String>[if (c.heroImage.isNotEmpty) c.heroImage, ...c.images];
    return all.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_contentLoading) return _buildLoadingScaffold();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: context.scrollPhysics,
        slivers: [
          SliverAppBar(
            pinned: true,
            surfaceTintColor: AppColors.white,
            shadowColor: Colors.transparent,
            expandedHeight: _appBarHeight,
            backgroundColor: AppColors.white,
            // elevation: _collapsed ? 2 : 0,
            elevation: 0,
            // leading: _CircleIconButton(
            //   icon: Icons.arrow_back,
            //   overPhoto: !_collapsed,
            //   iconColor: _collapsed ? _navy : AppColors.white,
            //   onTap: () => Navigator.of(context).maybePop(),
            // ),
            leadingWidth: context.w(40),
            leading: Padding(
              padding: EdgeInsets.only(left: context.w(8)),
              child: _CircleIconButton(
                icon: Icons.arrow_back,
                overPhoto: !_collapsed,
                iconColor: Colors.white,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            title: _collapsed
                ? Text(
                    widget.hotelName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(16),
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  )
                : null,
            actions: [
              if (!_collapsed)
                Padding(
                  padding: EdgeInsets.only(right: context.w(6)),
                  child: _CircleIconButton(
                    icon: _favorite ? Icons.favorite : Icons.favorite_border,
                    overPhoto: true,
                    iconColor: _favorite ? Colors.red : Colors.white,
                    onTap: () => setState(() => _favorite = !_favorite),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(right: context.w(12)),
                child: _CircleIconButton(
                  icon: Icons.share,
                  overPhoto: !_collapsed,
                  iconColor: _collapsed ? _navy : Colors.white,
                  onTap: _shareHotel,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildHeroBackground()),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_collapsed ? _tabBarHeight : 0),
              child: _collapsed ? _buildTabBar() : const SizedBox.shrink(),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // The photo strip now lives inside the app bar and hangs
              // half below the hero image; this spacer clears the part of
              // the strip that dips into the content area, so the Overview
              // section doesn't butt against it.
              SizedBox(height: _stripOverlap - context.h(35)),
              _buildOverviewSection(),
              _buildLocationSection(),
              _buildReviewsSection(),
              _buildAboutSection(),
              _buildPropertyRulesSection(),
              SizedBox(height: context.h(20)),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// Full-page shimmer shown until Content resolves (success or failure) —
  /// per-image loading is still handled by each [CachedNetworkImage]'s own
  /// shimmer placeholder once this gate lifts.
  Widget _buildLoadingScaffold() {
    Widget bar(double width, double height, {BorderRadius? radius}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius ?? BorderRadius.circular(context.r(4))),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _navy),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(double.infinity, _heroHeight, radius: BorderRadius.zero),
              Padding(
                padding: context.responsivePadding.copyWith(top: context.gapMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(context.wp(60), context.h(20)),
                    SizedBox(height: context.h(10)),
                    bar(context.wp(40), context.h(14)),
                    SizedBox(height: context.h(16)),
                    Row(
                      children: [
                        Expanded(child: bar(double.infinity, context.h(28))),
                        SizedBox(width: context.gapSmall),
                        Expanded(child: bar(double.infinity, context.h(28))),
                      ],
                    ),
                    SizedBox(height: context.gapLarge),
                    bar(context.wp(30), context.h(16)),
                    SizedBox(height: context.gapSmall),
                    bar(double.infinity, context.h(70)),
                    SizedBox(height: context.gapLarge),
                    bar(context.wp(30), context.h(16)),
                    SizedBox(height: context.gapSmall),
                    bar(double.infinity, context.h(160)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hero image + overlapping photo strip, both inside the app bar's
  /// bounds. The hero image only occupies the top [_heroHeight] pixels;
  /// the strip is positioned so its vertical center sits on the image's
  /// bottom edge — half over the image, half below (in the extra
  /// [_stripOverlap] of app-bar room). Because everything is inside the
  /// app bar, nothing is clipped.
  Widget _buildHeroBackground() {
    final images = _images;
    final heroImage = images.isNotEmpty ? images.first : '';
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero image occupies only the top _heroHeight, so the bottom
        // _stripOverlap of the app bar is free for the strip to dip into.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              heroImage.isEmpty
                  ? Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.hotel,
                        size: context.w(56),
                        color: Colors.grey.shade500,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: heroImage,
                      cacheManager: FastNetworkImageCacheManager.instance,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade200,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.hotel,
                          size: context.w(56),
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
              // Bottom gradient for status-bar and strip legibility.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: context.h(110),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Photo strip — centered on the image's bottom edge. Its top
        // `_stripOverlap` sits over the hero image, its bottom
        // `_stripOverlap` sits in the empty app-bar room below the image.
        if (images.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            top: _heroHeight - _stripOverlap,
            height: _stripCardHeight,
            child: _buildPhotoStrip(),
          ),
      ],
    );
  }

  /// The photo strip itself. Now that its outer position is handled by
  /// [_buildHeroBackground], this just renders the card at its natural
  /// size — no more Stack/Positioned juggling.
  Widget _buildPhotoStrip() {
    final images = _images;
    if (images.isEmpty) return const SizedBox.shrink();
    const visibleCount = 6;
    final visible = images.take(visibleCount).toList();
    final remaining = images.length - visible.length;

    return Padding(
      padding: context.horizontalPadding,
      child: DecoratedBox(
        // The shadow has to live on a sibling behind the clipped/blurred
        // card — ClipRRect would otherwise clip it away too.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(4)),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.12),
          //     blurRadius: context.r(14),
          //     offset: Offset(0, context.h(6)),
          //   ),
          // ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.r(8)),
          // Frosted glass: blurs whatever's actually behind this card in
          // the composited scene — the hero photo it overlaps — instead of
          // a blur baked into the hero that an opaque card would hide.
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.h(14),
            ),
            color: AppColors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(visible.length, (i) {
                final isLast = i == visible.length - 1;
                final showMore = isLast && remaining > 0;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : context.w(8)),
                    child: GestureDetector(
                      onTap: _openPhotoGallery,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(context.r(4)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _thumbImage(visible[i]),
                            if (showMore)
                              Container(
                                color: Colors.black.withValues(alpha: 0.55),
                                alignment: Alignment.center,
                                child: Text(
                                  '+$remaining',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: context.fs(14),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbImage(String url) {
    if (url.isEmpty) return Container(color: Colors.grey.shade200);
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: FastNetworkImageCacheManager.instance,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Container(color: Colors.grey.shade200),
      errorWidget: (context, url, error) =>
          Container(color: Colors.grey.shade200),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(vertical: context.h(10)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: context.scrollPhysics,
        padding: EdgeInsets.symmetric(horizontal: context.w(12)),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _activeTabIndex == index;
            return Padding(
              padding: EdgeInsets.only(right: context.w(10)),
              child: GestureDetector(
                onTap: () => _scrollToTab(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(8),
                    vertical: context.h(4),
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _blue.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(context.r(6)),
                    border: Border.all(color: isSelected ? _blue : _border, width: 0.5),
                  ),
                  child: Text(
                    _tabs[index].label,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w700,
                      color: isSelected ? _blue : _muted,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final c = _content;
    return Padding(
      key: _overviewKey,
      padding: context.responsivePadding.copyWith(
        top: context.gapSmall,
        bottom: context.gapMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hotelName,
            style: TextStyle(
              fontSize: context.fs(20),
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
          if (c != null && c.starRating > 0) ...[
            SizedBox(height: context.h(8)),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < c.starRating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: context.w(15),
                  ),
                ),
                SizedBox(width: context.w(6)),
                Text(
                  c.starRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ],
          if (c != null &&
              (c.addressLine1.isNotEmpty || c.city.isNotEmpty)) ...[
            SizedBox(height: context.h(10)),
            GestureDetector(
              onTap: () =>
                  _scrollToTab(_tabs.indexWhere((t) => t.label == 'Location')),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/Newimage/mapIcon.png',
                    width: context.w(16),
                    height: context.w(16),
                    fit: BoxFit.contain,
                  ),
                  // Icon(Icons.location_on, size: context.w(16), color: _muted),
                  SizedBox(width: context.w(8)),
                  Expanded(
                    child: Text(
                      [
                        c.addressLine1,
                        c.city,
                        c.state,
                        c.country,
                      ].where((s) => s.isNotEmpty).join(', '),
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: context.w(20), color: AppColors.AppBlue),
                ],
              ),
            ),
          ],
          SizedBox(height: context.gapMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(
                null,
                '${_formatDate(widget.checkIn)} - ${_formatDate(widget.checkOut)}',
                assetIcon: 'assets/NewIcons/calender.png',
              ),
              SizedBox(width: context.gapSmall),
              _infoChip(
                Icons.person,
                '${widget.adults + widget.children} Guest${(widget.adults + widget.children) == 1 ? '' : 's'} / ${widget.rooms.length} room${widget.rooms.length == 1 ? '' : 's'}',
              ),
            ],
          ),
          if (c != null &&
              (c.checkinBeginTime.isNotEmpty || c.checkoutTime.isNotEmpty)) ...[
            SizedBox(height: context.h(10)),
            // Center(
            //   child: Text(
            //     'Check in : ${c.checkinBeginTime.isNotEmpty ? c.checkinBeginTime : '—'}  /  Check out : ${c.checkoutTime.isNotEmpty ? c.checkoutTime : '—'}',
            //     style: TextStyle(
            //       fontSize: context.fs(8),
            //       color: _muted,
            //       fontWeight: FontWeight.w400,
            //     ),
            //   ),
            // ),
            Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: context.fs(8),
                    color: _muted,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    const TextSpan(text: 'Check in : '),
                    TextSpan(
                      text: c.checkinBeginTime.isNotEmpty
                          ? c.checkinBeginTime
                          : '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '  /  Check out : '),
                    TextSpan(
                      text: c.checkoutTime.isNotEmpty
                          ? c.checkoutTime
                          : '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: context.gapMedium),
          Divider(color: AppColors.lightsubhead, height: 11),
          SizedBox(height: context.gapLarge),
          _buildAmenitiesPreview(c),
        ],
      ),
    );
  }

  Widget _infoChip(IconData? icon, String label, {String? assetIcon}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(6),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(4)),
        border: Border.all(color: AppColors.AppBlue, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(icon, size: context.w(12), color: _blue),
          assetIcon != null
              ? Image.asset(
            assetIcon,
            width: context.w(16),
            height: context.w(16),
            fit: BoxFit.contain,
            color: AppColors.AppBlue,
          )
              : Icon(icon, size: context.w(16), color: _blue),
          SizedBox(width: context.w(6)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(8),
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact 3-facility preview shown right under Overview — "See All
  /// Amenities" opens [AkHotelAmenitiesScreen] with the hotel's full
  /// facilities list.
  Widget _buildAmenitiesPreview(AkHotelDetailContentEntity? c) {
    final facilities = c?.facilities ?? const <String>[];
    // Nothing real to preview — hide the whole block, title included,
    // rather than a heading over an empty/placeholder message.
    if (facilities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(
            fontSize: context.fs(16),
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
        SizedBox(height: context.gapSmall),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(12),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
          child: Row(
            children: facilities
                .take(3)
                .map((f) => Expanded(child: _amenityPreviewItem(f)))
                .toList(),
          ),
        ),
        SizedBox(height: context.h(6)),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () =>
                _scrollToTab(_tabs.indexWhere((t) => t.label == 'Amenities')),
            child: Text(
              'See All Amenities',
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _amenityPreviewItem(String facility) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconForFacility(facility), size: context.w(20), color: _navy),
        SizedBox(height: context.h(6)),
        Text(
          facility,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: context.fs(10.5),
            color: _navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _iconForFacility(String name) {
    final n = name.toLowerCase();
    if (n.contains('pool')) return Icons.pool;
    if (n.contains('restaurant') || n.contains('dining'))
      return Icons.restaurant;
    if (n.contains('spa') || n.contains('sauna') || n.contains('steam'))
      return Icons.spa;
    if (n.contains('wifi') || n.contains('internet')) return Icons.wifi;
    if (n.contains('parking')) return Icons.local_parking;
    if (n.contains('gym') || n.contains('fitness')) return Icons.fitness_center;
    if (n.contains('bar')) return Icons.local_bar;
    if (n.contains('air condition')) return Icons.ac_unit;
    if (n.contains('breakfast')) return Icons.free_breakfast;
    if (n.contains('laundry')) return Icons.local_laundry_service;
    if (n.contains('elevator') || n.contains('lift')) return Icons.elevator;
    return Icons.check_circle_outline;
  }

  Widget _buildLocationSection() {
    final c = _content;
    final lat = c?.lat;
    final long = c?.long;

    return Container(
      key: _locationKey,
      padding: context.responsivePadding.copyWith(
        top: context.gapLarge,
        bottom: context.gapMedium,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          if (c != null && c.addressLine1.isNotEmpty) ...[
            SizedBox(height: context.gapSmall),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: _navy,
                  height: 1,
                ),
                children: [
                  const TextSpan(
                    text: 'Address: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: c.addressLine1,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
          if (lat != null && long != null) ...[
            SizedBox(height: context.h(6)),
            _buildUseMyLocationRow(),
          ],
          SizedBox(height: context.gapMedium),
          if (lat == null || long == null)
            Container(
              height: context.h(160),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off,
                    size: context.w(36),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: context.h(8)),
                  Text(
                    'Location not available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            _buildMapPreview(LatLng(lat, long)),
          SizedBox(height: context.gapMedium),
          // Decorative — no distance-lookup backend exists yet, so this
          // never claims to compute a real result; kept purely as the input
          // affordance the reference shows.
          Container(
            height: context.h(44),
            padding: EdgeInsets.symmetric(horizontal: context.w(12)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.r(10)),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: context.iconSmall,
                  color: Colors.grey.shade500,
                ),
                SizedBox(width: context.gapSmall),
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      fontSize: context.bodyMedium,
                      color: _navy,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search property distance from...',
                      hintStyle: TextStyle(
                        fontSize: context.bodyMedium,
                        color: Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(LatLng position) {
    return Container(
      height: context.h(180),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: context.r(8),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(8)),
        child: InkWell(
          onTap: () => _openInGoogleMaps(position),
          child: Stack(
            children: [
              Image.asset(
                'assets/images/googleMap.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: context.w(40),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: context.h(8)),
                        Text(
                          'Map View',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: context.fs(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Positioned(
              //   bottom: context.h(12),
              //   right: context.w(12),
              //   child: Container(
              //     padding: EdgeInsets.symmetric(
              //       horizontal: context.w(10),
              //       vertical: context.h(5),
              //     ),
              //     decoration: BoxDecoration(
              //       color: Colors.black.withValues(alpha: 0.6),
              //       borderRadius: BorderRadius.circular(context.r(6)),
              //     ),
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Icon(
              //           Icons.open_in_new,
              //           size: context.w(14),
              //           color: Colors.white,
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  /// Device-location affordance for the Location section: on tap, requests
  /// permission (if needed) and the current position, then shows the real
  /// distance from the user to this hotel's own coordinates — nothing here
  /// is a hardcoded/guessed location.
  Widget _buildUseMyLocationRow() {
    if (_distanceKm != null) {
      return Row(
        children: [
          Icon(Icons.my_location, size: context.w(14), color: Colors.green.shade700),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Text(
              '${_distanceKm!.toStringAsFixed(1)} km from your current location',
              style: TextStyle(fontSize: context.fs(11.5), color: Colors.green.shade700, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        GestureDetector(
          onTap: _locating ? null : _useMyLocation,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _locating
                  ? SizedBox(
                      width: context.w(13),
                      height: context.w(13),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.AppBlue),
                    )
                  : Icon(Icons.my_location, size: context.w(14), color: _blue),
              SizedBox(width: context.w(6)),
              Text(
                _locating ? 'Calculating distance from you...' : 'Show distance from me',
                style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: _blue),
              ),
            ],
          ),
        ),
        if (_locationError != null) ...[
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              _locationError!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: context.fs(10.5), color: Colors.red.shade400),
            ),
          ),
        ],
      ],
    );
  }

  void _openInGoogleMaps(LatLng position) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  /// Maps the star rating to a short label — the only "review" copy this
  /// flow can show without inventing one, since the Content API carries no
  /// per-guest review text, only the aggregate [c.starRating].
  String _ratingLabel(double rating) {
    switch (rating.round()) {
      case 5:
        return 'Excellent Stay';
      case 4:
        return 'Very Good Stay';
      case 3:
        return 'Good Stay';
      case 2:
        return 'Fair Stay';
      case 1:
        return 'Below Average';
      default:
        return '';
    }
  }

  /// Prefers the real aggregate *guest* review (`userReview.rating`/
  /// `.count`) when Content actually supplies one — many hotels/providers
  /// on this backend don't, in which case this falls back to
  /// [AkHotelDetailContentEntity.starRating] (the hotel's own
  /// classification, e.g. "4-star hotel" — a different field from a
  /// guest-driven score, so it's labeled and star-counted differently, not
  /// presented as if it were guest sentiment). No per-review text/reviewer
  /// is fabricated either way, since Content gives us only one aggregate
  /// number, never a review list — see [AkHotelReviewScreen] for the same
  /// constraint on the full screen (only offered when the real guest
  /// review exists, since a star classification has nothing further to
  /// show).
  Widget _buildReviewsSection() {
    final c = _content;
    final reviewRating = c?.reviewRating ?? 0;
    final reviewCount = c?.reviewCount ?? 0;
    final hasGuestReview = reviewRating > 0 && reviewCount > 0;
    final starRating = c?.starRating ?? 0;
    // No real rating of either kind — hide the section (and its key)
    // entirely rather than a heading over a "not available" placeholder.
    if (!hasGuestReview && starRating <= 0) return const SizedBox.shrink();
    final rating = hasGuestReview ? reviewRating : starRating;
    final label = _ratingLabel(rating);
    final blurb = (c?.descriptions ?? const <String>[])
        .map(_stripHtmlTags)
        .firstWhere((d) => d.isNotEmpty, orElse: () => '');

    return Container(
      key: _reviewsKey,
      padding: context.responsivePadding.copyWith(
        top: context.gapLarge,
        bottom: context.gapMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews & Ratings',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          SizedBox(height: context.gapSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.w(14)),
                decoration: BoxDecoration(
                  border: Border.all(color: _border, width: 0.5),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(10),
                            vertical: context.h(6),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            border: Border.all(color: AppColors.AppBlue),
                            borderRadius: BorderRadius.circular(context.r(8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: context.w(16),
                              ),
                              SizedBox(width: context.w(4)),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.AppBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.gapMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label.isNotEmpty ? label : 'Guest rating for this property',
                                style: TextStyle(
                                  fontSize: context.fs(13),
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                hasGuestReview
                                    ? '$reviewCount User Rating${reviewCount == 1 ? '' : 's'}'
                                    : '${starRating.toStringAsFixed(0)}-Star Hotel',
                                style: TextStyle(fontSize: context.fs(11), color: _muted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (blurb.isNotEmpty) ...[
                      SizedBox(height: context.gapSmall),
                      Text(
                        blurb,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(12),
                          color: _muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // SizedBox(height: context.h(6)),
              // GestureDetector(
              //   onTap: () => Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) => AkHotelReviewScreen(
              //         hotelName: widget.hotelName,
              //         rating: rating,
              //         reviewCount: hasGuestReview ? reviewCount : 0,
              //       ),
              //     ),
              //   ),
              //   behavior: HitTestBehavior.opaque,
              //   child: Text(
              //     'View More',
              //     style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: AppColors.AppBlue),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final descriptions = (_content?.descriptions ?? const <String>[])
        .map(_stripHtmlTags)
        .where((d) => d.isNotEmpty)
        .toList();
    return Container(
      key: _aboutKey,
      padding: context.responsivePadding.copyWith(
        top: context.gapLarge,
        bottom: context.gapMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          SizedBox(height: context.gapSmall),
          if (descriptions.isEmpty)
            Text(
              'No description available for this hotel yet.',
              style: TextStyle(fontSize: context.fs(12), color: _muted),
            )
          else
            _ClampedTextBox(
              text: descriptions.join(' '),
              style: TextStyle(fontSize: context.fs(12.5), color: _muted, height: 1.45),
              padding: EdgeInsets.all(context.w(14)),
              borderColor: _border,
              borderRadius: context.r(12),
              onViewMore: () => _openAboutDrawer(descriptions),
            ),
        ],
      ),
    );
  }

  void _openAboutDrawer(List<String> descriptions) {
    final categorized = _categorizeAboutText(descriptions);
    if (categorized.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AboutDrawer(images: _images, categorized: categorized),
    );
  }

  Widget _buildPropertyRulesSection() {
    final c = _content;
    final rules = [
      ...(c?.policies ?? const <String>[]),
      ...(c?.checkinSpecialInstructions ?? const <String>[]),
    ].map(_stripHtmlTags).where((d) => d.isNotEmpty).toList();
    final visible = rules.take(2).toList();
    return Container(
      key: _rulesKey,
      padding: context.responsivePadding.copyWith(
        top: context.gapLarge,
        bottom: context.gapLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Rules',
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          SizedBox(height: context.gapSmall),
          if (rules.isEmpty)
            Text(
              'No property rules listed for this hotel.',
              style: TextStyle(fontSize: context.fs(12), color: _muted),
            )
          else ...[
            for (final r in visible) _bulletLine(r),
            if (rules.length > 2)
              _viewMoreToggle(false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AkHotelPropertyRulesScreen(hotelName: widget.hotelName, rules: rules),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _bulletLine(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.h(6)),
            child: Container(
              width: context.w(4),
              height: context.w(4),
              decoration: const BoxDecoration(
                color: _muted,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.fs(12.5),
                color: _muted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewMoreToggle(bool expanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            expanded ? 'View Less' : 'View More',
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          Icon(
            expanded ? Icons.expand_less : Icons.chevron_right,
            size: context.w(16),
            color: _blue,
          ),
        ],
      ),
    );
  }

  /// Vendor description/board-basis text sometimes arrives as raw HTML —
  /// strip tags and decode the handful of entities that commonly survive
  /// that, so only plain text is shown.
  String _stripHtmlTags(String html) {
    if (html.isEmpty) return html;
    var text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.symmetric(
          horizontal: context.gapLarge,
          vertical: context.gapMedium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FutureBuilder<DataState<AkHotelRoomsResultEntity>>(
                future: _roomsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: context.h(20),
                        width: context.w(90),
                        color: Colors.white,
                      ),
                    );
                  }
                  final result = snapshot.data;
                  double? minPrice;
                  if (result is DataSuccess<AkHotelRoomsResultEntity>) {
                    final rates = [
                      for (final rec
                          in result.data?.recommendations ??
                              const <AkHotelRecommendationEntity>[])
                        for (final rg in rec.roomGroups) rg.totalRate,
                    ];
                    if (rates.isNotEmpty)
                      minPrice = rates.reduce((a, b) => a < b ? a : b);
                  }
                  if (minPrice == null) {
                    return Text(
                      'Price unavailable',
                      style: TextStyle(fontSize: context.fs(12), color: _muted),
                    );
                  }
                  final resolvedMinPrice = minPrice;
                  return ValueListenableBuilder<String>(
                    valueListenable: CurrencyConverter.currencyListenable,
                    builder: (context, currency, _) {
                      final converted = CurrencyConverter.convert(
                        amount: resolvedMinPrice,
                        fromCurrency: 'INR',
                        toCurrency: currency,
                      );
                      final formatted = CurrencyConverter.format(
                        converted,
                        currency,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatted,
                            style: TextStyle(
                              fontSize: context.fs(20),
                              fontWeight: FontWeight.w900,
                              color: _navy,
                            ),
                          ),
                          Text(
                            'Includes taxes and fees',
                            style: TextStyle(
                              fontSize: context.fs(10),
                              color: _muted,
                            ),
                          ),
                          Text(
                            'Per night (${widget.checkIn} - ${widget.checkOut})',
                            style: TextStyle(
                              fontSize: context.fs(10),
                              color: _muted,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(width: context.gapMedium),
            ElevatedButton(
              onPressed: _openRoomOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(28),
                  vertical: context.h(14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
              ),
              child: Text(
                'SELECT ROOM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: context.fs(13),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final parsed = DateFormat('dd/MM/yyyy').parse(date);
    return DateFormat('dd MMM').format(parsed);
  }
}

/// Back/heart/share button — a translucent dark circle with a white icon
/// while floating over the hero photo, a plain icon once the header
/// collapses to the compact white bar (matching the reference exactly).
// class _CircleIconButton extends StatelessWidget {
//   final IconData icon;
//   final bool overPhoto;
//   final Color iconColor;
//   final VoidCallback onTap;
//
//   const _CircleIconButton({
//     required this.icon,
//     required this.overPhoto,
//     required this.iconColor,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: context.w(24),
//         height: context.w(24),
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: overPhoto
//               ? Colors.black.withValues(alpha: 0.35)
//               : Colors.transparent,
//           shape: BoxShape.circle,
//         ),
//         child: Icon(icon, size: context.w(18), color: iconColor),
//       ),
//     );
//   }
// }
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final bool overPhoto;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.overPhoto,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFavourite = icon == Icons.favorite;
    final isBackArrow = icon == Icons.arrow_back;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.w(24),
        height: context.w(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: overPhoto
              ? (isBackArrow
              ? AppColors.black
              : const Color(0xD6FFFFFF))
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: context.w(18),
          color: isFavourite ? Colors.red : Colors.white,
        ),
      ),
    );
  }
}

/// Category order for the About drawer's chip row. The Content API gives
/// `descriptions` as a flat list of paragraphs with no category of its
/// own, so — same approach as the amenities categorizer — each paragraph
/// is bucketed by keyword, defaulting to "Overview" rather than dropped.
const _aboutCategoryOrder = ['Overview', 'Food & Dining', 'Rooms', 'Facilities & Activities'];

Map<String, List<String>> _categorizeAboutText(List<String> descriptions) {
  final map = <String, List<String>>{for (final c in _aboutCategoryOrder) c: []};
  for (final d in descriptions) {
    final n = d.toLowerCase();
    if (n.contains('restaurant') || n.contains('dining') || n.contains('breakfast') || n.contains('food') || n.contains('cuisine') || n.contains('bar') || n.contains('buffet')) {
      map['Food & Dining']!.add(d);
    } else if (n.contains('room') || n.contains('bed') || n.contains('suite') || n.contains('cottage') || n.contains('balcon')) {
      map['Rooms']!.add(d);
    } else if (n.contains('pool') || n.contains('gym') || n.contains('spa') || n.contains('facilit') || n.contains('activit') || n.contains('wifi') || n.contains('parking') || n.contains('garden')) {
      map['Facilities & Activities']!.add(d);
    } else {
      map['Overview']!.add(d);
    }
  }
  map.removeWhere((key, value) => value.isEmpty);
  return map;
}

/// Bordered text box clamped to 4 lines, with a "View More" link placed
/// *outside* the box (bottom-right, below its border) — shown only when the
/// text actually overflows at the box's real width, checked via
/// [TextPainter] rather than a guessed character count.
class _ClampedTextBox extends StatelessWidget {
  static const _maxLines = 4;

  final String text;
  final TextStyle style;
  final EdgeInsets padding;
  final Color borderColor;
  final double borderRadius;
  final VoidCallback onViewMore;

  const _ClampedTextBox({
    required this.text,
    required this.style,
    required this.padding,
    required this.borderColor,
    required this.borderRadius,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = (constraints.maxWidth - padding.horizontal).clamp(0.0, double.infinity);
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _maxLines,
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: innerWidth);
        final overflowed = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              padding: padding,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Text(text, maxLines: _maxLines, overflow: TextOverflow.ellipsis, style: style),
            ),
            if (overflowed) ...[
              SizedBox(height: context.h(6)),
              GestureDetector(
                onTap: onViewMore,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'View More',
                  style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w700, color: AppColors.AppBlue),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Bottom drawer for the full "About" content — drag handle, category
/// chips (filtering, not scrolling, since each category is only a
/// handful of paragraphs), the hotel's own gallery carousel, and a
/// floating close button just above the sheet's top-right corner, matching
/// the app's existing bottom-sheet chrome (see the room/guest picker in
/// hotel_search_card.dart).
class _AboutDrawer extends StatefulWidget {
  final List<String> images;
  final Map<String, List<String>> categorized;

  const _AboutDrawer({required this.images, required this.categorized});

  @override
  State<_AboutDrawer> createState() => _AboutDrawerState();
}

class _AboutDrawerState extends State<_AboutDrawer> {
  late String _active = widget.categorized.keys.first;

  @override
  Widget build(BuildContext context) {
    final items = widget.categorized[_active] ?? const <String>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(right: context.w(20), bottom: context.h(10)),
          child: Align(alignment: Alignment.centerRight, child: _closeButton(context)),
        ),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(24))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.w(20), context.h(10), context.w(20), context.h(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _handle(context)),
                    SizedBox(height: context.h(16)),
                    Text(
                      'About',
                      style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    SizedBox(height: context.h(14)),
                    if (widget.categorized.length > 1) _buildChips(context),
                    SizedBox(height: context.h(14)),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.images.isNotEmpty) ...[
                              AkHotelImageCarousel(
                                images: widget.images,
                                height: context.h(200),
                                borderRadius: BorderRadius.circular(context.r(16)),
                              ),
                              SizedBox(height: context.h(16)),
                            ],
                            for (final item in items) _bullet(context, item),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: context.scrollPhysics,
      child: Row(
        children: [
          for (final category in widget.categorized.keys)
            Padding(
              padding: EdgeInsets.only(right: context.w(8)),
              child: GestureDetector(
                onTap: () => setState(() => _active = category),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(8)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(color: _active == category ? AppColors.AppBlue : AppColors.lightsubhead,  width: _active == category ? 1.0 : 0.5,),
                    color: _active == category ? AppColors.AppBlue.withValues(alpha: 0.06) : Colors.white,
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w400,
                      color: _active == category ? AppColors.AppBlue : AppColors.subhead,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.h(7)),
            child: Container(
              width: context.w(5),
              height: context.w(5),
              decoration: const BoxDecoration(color: AppColors.subhead, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: context.fs(12), color: AppColors.subhead, height: 1.45, fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: context.w(34),
        height: context.w(34),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(Icons.close_rounded, size: context.w(19), color: AppColors.black),
      ),
    );
  }

  Widget _handle(BuildContext context) {
    return Container(
      width: context.w(103),
      height: context.h(8),
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(context.r(24))),
    );
  }
}