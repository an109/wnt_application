import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/fast_network_image_cache_manager.dart';
import '../../../../common_widgets/hotel_loading_indicator.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/services/hotel_session_service.dart';
import '../../../../injection_container.dart';
import '../../../Hotel_Details/presentation/bloc/hotel_details_bloc.dart';
import '../../../Hotel_Details/presentation/screens/main_hotel_detail_screen.dart';
import '../../domain/entities/hotel_ui_entity.dart';
import '../bloc/hotel_bloc.dart';
import '../bloc/hotel_event.dart';
import '../bloc/hotel_state.dart';
import '../../../Hotel/Filter_drawer/filter_drawer.dart';

class HotelListingScreen extends StatefulWidget {
  final String cityCode;
  final String checkIn;
  final String checkOut;
  final String guestNationality;
  final Map<String, dynamic>? filters;
  final List<Map<String, dynamic>>? paxRooms;

  const HotelListingScreen({
    super.key,
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    required this.guestNationality,
    this.filters,
    this.paxRooms,
  });

  @override
  State<HotelListingScreen> createState() => _HotelListingScreenState();
}

class _HotelListingScreenState extends State<HotelListingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFilterApplied = false;
  static const _blue = Color(0xFF1769F6);
  static const _pageBg = Color(0xFFF3F6FC);

  // All hotels returned by the API (unfiltered client-side)
  List<HotelUiModel> _allHotels = [];
  // Hotels after client-side filters applied (star, price, amenities)
  List<HotelUiModel> _displayedHotels = [];
  // Client-side filter values extracted from the drawer's filter map
  Map<String, dynamic> _activeClientFilters = {};
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Mark the start of the 15-minute TBO search session (Search → PreBook → Book)
    HotelSessionService.instance.markSearchStarted();
    _loadInitialHotels();
  }

  // Add this method to _HotelListingScreenState class
  void _navigateToHotelDetails(HotelUiModel hotel) {
    print('HotelListingScreen: Navigating to details for ${hotel.hotelName}');
    print('HotelListingScreen: Hotel Code: ${hotel.hotelCode}');
    print(
      'HotelListingScreen: CheckIn: ${widget.checkIn}, CheckOut: ${widget.checkOut}',
    );

    // Safely extract guest data from paxRooms
    int adults = 1;
    int children = 0;

    if (widget.paxRooms != null && widget.paxRooms!.isNotEmpty) {
      final firstRoom = widget.paxRooms!.first;
      adults = (firstRoom['Adults'] as int?) ?? 1;
      children = (firstRoom['Children'] as int?) ?? 0;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => sl<HotelDetailsBloc>(),
          child: HotelDetailsScreen(
            hotelCode: hotel.hotelCode,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            adults: adults,
            children: children,
          ),
        ),
      ),
    );
  }

  List<HotelUiModel> _applyClientFilters(List<HotelUiModel> hotels) {
    var result = hotels;
    final f = _activeClientFilters;

    final minPrice = f['min_price'];
    final maxPrice = f['max_price'];
    final starRating = f['star_rating'];
    final amenities = f['amenities'];

    if (minPrice != null) {
      result = result.where((h) => h.numericPrice >= (minPrice as num).toDouble()).toList();
    }
    if (maxPrice != null) {
      result = result.where((h) => h.numericPrice <= (maxPrice as num).toDouble()).toList();
    }
    if (starRating != null) {
      result = result.where((h) => h.rating == (starRating as num).toInt()).toList();
    }
    if (amenities != null && (amenities as List).isNotEmpty) {
      final required = (amenities as List).map((a) => a.toString().toLowerCase()).toList();
      result = result.where((h) {
        final facilityText = h.facilities.join(' ').toLowerCase();
        return required.every((a) => facilityText.contains(a));
      }).toList();
    }

    return result;
  }

  void _loadInitialHotels() {
    setState(() {
      _allHotels = [];
      _displayedHotels = [];
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isInitialLoading = true;
    });

    context.read<HotelBloc>().add(
      LoadHotelsEvent(
        cityCode: widget.cityCode,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guestNationality: widget.guestNationality,
        page: 1,
        pageSize: 20,
        filters: widget.filters,
        paxRooms: widget.paxRooms,
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && !_hasReachedMax && _displayedHotels.isNotEmpty) {
        setState(() => _isLoadingMore = true);

        final blocState = context.read<HotelBloc>().state;
        int nextPage = 2;
        if (blocState is HotelLoaded) {
          nextPage = blocState.currentPage + 1;
        }

        context.read<HotelBloc>().add(
          LoadMoreHotelsEvent(
            cityCode: widget.cityCode,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            guestNationality: widget.guestNationality,
            nextPage: nextPage,
            pageSize: 20,
            filters: widget.filters,
            paxRooms: widget.paxRooms,
          ),
        );
      }
    }
  }

  void _onRefresh() async {
    setState(() {
      _isLoadingMore = false;
    });

    context.read<HotelBloc>().add(
      RefreshHotelsEvent(
        cityCode: widget.cityCode,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guestNationality: widget.guestNationality,
        filters: widget.filters,
        paxRooms: widget.paxRooms,
      ),
    );
  }

  void _applyFilters(Map<String, dynamic> newFilters) {
    // Separate client-side fields from TBO fields
    const clientKeys = {'min_price', 'max_price', 'star_rating', 'amenities'};
    final clientFilters = <String, dynamic>{};
    final tboFilters = <String, dynamic>{};
    for (final entry in newFilters.entries) {
      if (clientKeys.contains(entry.key)) {
        clientFilters[entry.key] = entry.value;
      } else {
        tboFilters[entry.key] = entry.value;
      }
    }

    setState(() {
      _isFilterApplied = true;
      _allHotels = [];
      _displayedHotels = [];
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isInitialLoading = true;
      _activeClientFilters = clientFilters;
    });

    context.read<HotelBloc>().add(
      LoadHotelsEvent(
        cityCode: widget.cityCode,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guestNationality: widget.guestNationality,
        page: 1,
        pageSize: 20,
        filters: tboFilters.isNotEmpty ? tboFilters : newFilters,
        paxRooms: widget.paxRooms,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _isFilterApplied = false;
      _activeClientFilters = {};
      _allHotels = [];
      _displayedHotels = [];
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isInitialLoading = true;
    });
    _loadInitialHotels();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HotelFilterDrawer(
        onFiltersApplied: _applyFilters,
        onClearFilters: _clearFilters,
        isFilterApplied: _isFilterApplied,
      ),
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _pageBg,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Image.asset(
              "assets/images/wander_logo.png",
              height: 35,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.hotel, size: 35),
            ),
          ),
        ],
      ),
      backgroundColor: _pageBg,
      body: BlocListener<HotelBloc, HotelState>(
        listener: (context, state) {
          if (state is HotelError) {
            if (_displayedHotels.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            setState(() {
              _isLoadingMore = false;
              _isInitialLoading = false;
            });
          }

          if (state is HotelLoaded) {
            final newHotels = state.hotels
                .map((entity) => HotelUiModel.fromEntity(entity))
                .toList();

            setState(() {
              if (state.currentPage == 1) {
                _allHotels = newHotels;
              } else {
                _allHotels = [..._allHotels, ...newHotels];
              }
              _displayedHotels = _applyClientFilters(_allHotels);
              _hasReachedMax = state.hasReachedMax;
              _isLoadingMore = false;
              _isInitialLoading = false;
            });
          }

          if (state is HotelLoading && state is! HotelLoadMoreLoading) {
            if (_displayedHotels.isEmpty) {
              setState(() {
                _isInitialLoading = true;
              });
            }
          }
        },
        child: _buildHotelList(),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      floatingActionButton: _buildFilterBadge(),
    );
  }

  Widget _buildHotelList() {
    if (_displayedHotels.isEmpty && _isInitialLoading) {
      return const HotelLoadingIndicator();
    }

    if (_displayedHotels.isEmpty && !_isInitialLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _onRefresh(),
      color: _blue,
      child: ListView.builder(
        key: const ValueKey('hotel_list'),
        controller: _scrollController,
        physics: context.scrollPhysics,
        padding: context.horizontalPadding.copyWith(
          top: context.gapMedium,
          bottom: context.gapLarge + context.buttonHeight + context.gapLarge,
        ),
        itemCount: _displayedHotels.length + (_hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= _displayedHotels.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: context.gapMedium),
              child: Center(
                child: _isLoadingMore
                    ? SizedBox(
                        height: context.iconMedium,
                        width: context.iconMedium,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _blue,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          return HotelCard(
            hotel: _displayedHotels[index],
            onSelectRoom: () =>
                _navigateToHotelDetails(_displayedHotels[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: context.horizontalPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel_outlined,
              size: context.iconLarge * 2,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: context.gapLarge),
            Text(
              'No hotels found',
              style: TextStyle(
                fontSize: context.titleLarge,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: context.gapSmall),
            Text(
              'Try adjusting your filters or search criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyMedium,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: context.gapLarge),
            SizedBox(
              width: context.buttonWidth,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                  ),
                ),
                onPressed: _clearFilters,
                child: Text(
                  'Clear Filters',
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFilterBadge() {
    if (!_isFilterApplied) return null;

    return FloatingActionButton.small(
      onPressed: _clearFilters,
      backgroundColor: _blue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt, size: context.iconSmall, color: Colors.white),
          if (_isFilterApplied)
            Container(
              margin: EdgeInsets.only(top: context.gapSmall / 4),
              padding: EdgeInsets.symmetric(
                horizontal: context.gapSmall / 2,
                vertical: context.gapSmall / 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '1',
                style: TextStyle(
                  fontSize: context.labelSmall,
                  fontWeight: FontWeight.bold,
                  color: _blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HotelCard extends StatelessWidget {
  final HotelUiModel hotel;
  final VoidCallback? onSelectRoom;
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _border = Color(0xFFE2E7F0);
  static const _muted = Color(0xFF6B7280);

  const HotelCard({super.key, required this.hotel, this.onSelectRoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.07),
            blurRadius: context.r(16),
            offset: Offset(0, context.h(10)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(context.r(10))),
            child: AspectRatio(
              aspectRatio: context.isTablet ? 2.7 : 1.78,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HotelCardImage(imageUrl: hotel.image),
                  if (!hotel.isRefundable)
                    Positioned(
                      top: context.gapMedium,
                      left: context.gapMedium,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.gapSmall,
                          vertical: context.gapSmall / 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(context.r(10)),
                          color: const Color(0xFFFF4D4F),
                        ),
                        child: Text(
                          'Non-refundable',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.fs(11),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: context.gapMedium,
                    bottom: context.gapMedium,
                    child: _RatingPill(rating: hotel.rating),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(12),
              context.w(12),
              context.w(12),
              context.w(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.hotelName,
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: context.h(8)),

                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: '${hotel.address}, ${hotel.countryName}',
                ),

                if (hotel.roomInfo.trim().isNotEmpty) ...[
                  SizedBox(height: context.h(7)),
                  _InfoRow(icon: Icons.bed_outlined, text: hotel.roomInfo),
                ],

                if (hotel.mealType.isNotEmpty &&
                    hotel.mealType != 'Room_Only') ...[
                  SizedBox(height: context.h(10)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(6),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.r(12)),
                      color: const Color(0xFFEFFAF2),
                      border: Border.all(color: const Color(0xFFD7F3DE)),
                    ),
                    child: Text(
                      hotel.mealType.replaceAll('_', ' '),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: context.h(14)),
                Container(height: 1, color: _border),
                SizedBox(height: context.h(12)),

                context.isTablet || context.isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _PriceSection(hotel: hotel)),
                          SizedBox(width: context.gapLarge),
                          Expanded(
                            child: _ButtonsSection(
                              hotel: hotel,
                              onSelectRoom: onSelectRoom,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PriceSection(hotel: hotel),
                          SizedBox(height: context.gapSmall),
                          _ButtonsSection(
                            hotel: hotel,
                            onSelectRoom: onSelectRoom,
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hotel card's hero image. Plain [Image.network] re-fetches from scratch
/// every time the card rebuilds (every scroll, every time this list
/// re-sorts itself around a search match, every Rate poll) and decodes at
/// the source's full resolution — that combination was the actual cause of
/// slow/never-loading images, not a one-off glitch. CachedNetworkImage
/// caches to disk+memory so a hotel already seen loads instantly,
/// memCacheWidth caps the decoded bitmap size so large photos don't spend
/// time/memory decoding pixels the card can't even show, and
/// [FastNetworkImageCacheManager] bounds every fetch with a timeout so one
/// slow/hung host degrades to the fallback icon instead of wedging the
/// shared fetch queue for every other image on screen (see its doc comment
/// for why that queue-wedging was the actual "nothing loads" symptom this
/// app hit with the default cache manager).
class _HotelCardImage extends StatelessWidget {
  final String imageUrl;

  const _HotelCardImage({required this.imageUrl});

  Widget _fallback(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.hotel, size: context.iconLarge, color: Colors.grey.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _fallback(context);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: FastNetworkImageCacheManager.instance,
      fit: BoxFit.cover,
      // Card images never render wider than the screen, and are almost
      // always well under it — 800px covers every device this app targets
      // without decoding multi-thousand-pixel source photos for nothing.
      memCacheWidth: 800,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => _fallback(context),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: context.w(16), color: HotelCard._muted),
        SizedBox(width: context.gapSmall),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(13),
              color: HotelCard._muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingPill extends StatelessWidget {
  final int rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: context.r(10),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber,
            size: context.w(14),
          ),
        ),
      ),
    );
  }
}

class _ButtonsSection extends StatelessWidget {
  final HotelUiModel hotel;
  final VoidCallback? onSelectRoom;

  const _ButtonsSection({required this.hotel, this.onSelectRoom});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.h(48),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(8)),
          ),
        ),
        onPressed:
            onSelectRoom ??
            () {
              print('HotelCard: Book Now pressed for ${hotel.hotelCode}');
            },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: context.w(16)),
            SizedBox(width: context.w(8)),
            Text(
              'Book Now',
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSection extends StatelessWidget {
  final HotelUiModel hotel;

  const _PriceSection({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              hotel.price,
              style: TextStyle(
                fontSize: context.fs(20),
                fontWeight: FontWeight.w900,
                color: HotelCard._navy,
              ),
            ),
            // SizedBox(width: context.gapSmall),
            // Text(
            //   'per night',
            //   style: TextStyle(
            //     color: HotelCard._muted,
            //     fontSize: context.fs(12),
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
          ],
        ),
        SizedBox(height: context.h(3)),
        Text(
          'Total ${hotel.price} + ${hotel.taxes} taxes',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.fs(11),
            color: HotelCard._muted,
          ),
        ),
      ],
    );
  }
}
