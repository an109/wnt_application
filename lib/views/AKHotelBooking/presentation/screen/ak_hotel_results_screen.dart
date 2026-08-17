import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/hotel_loading_indicator.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/error/data_state.dart';
import '../../../Hotel/Filter_drawer/filter_drawer.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';
import '../../../Hotel_api/presentation/screen/hotel_listing.dart' show HotelCard;
import '../../../AKHotelResultContent/domain/entity/AKHotelResultContent_entity.dart';
import '../../../AKHotelResultContent/domain/usecase/AKHotelResultContent_usecase.dart';
import '../../../AKHotelResultRate/domain/entity/AKHotelResultRate_entity.dart';
import '../../../AKHotelResultRate/domain/usecase/AKHotelResultRate_usecase.dart';
import '../../../AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import 'ak_hotel_detail_screen.dart';

/// Results screen for the Akbar Hotels flow: Content (static hotel info)
/// and Rate (pricing) are independent, slower-resolving providers, so both
/// are fetched in parallel and merged by hotel id as each poll comes back —
/// a hotel only becomes a visible card once it has both. Reuses the
/// existing [HotelCard]/[HotelUiModel] presentational widgets from
/// Hotel_api so the on-screen look matches the old tbo-hotel listing
/// exactly; only the data source is new.
class AkHotelResultsScreen extends StatefulWidget {
  final String searchId;
  final String searchTracingKey;
  final String locationName;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final String nationality;
  /// The exact per-room adults/children/childAges the user searched with —
  /// the authoritative source of occupancy for the whole booking chain
  /// (threaded down to [AkHotelPriceConfirmScreen] so guest forms don't have
  /// to reverse-engineer how the Rooms API echoes/collapses occupancy).
  final List<AkHotelSearchInitRoomEntity> rooms;

  const AkHotelResultsScreen({
    super.key,
    required this.searchId,
    required this.searchTracingKey,
    required this.locationName,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.nationality,
    required this.rooms,
  });

  @override
  State<AkHotelResultsScreen> createState() => _AkHotelResultsScreenState();
}

class _AkHotelResultsScreenState extends State<AkHotelResultsScreen> {
  static const _blue = Color(0xFF1769F6);
  static const _pageBg = Color(0xFFF3F6FC);
  static const _maxRatePolls = 20;

  final ScrollController _scrollController = ScrollController();

  final Map<String, AkHotelContentItemEntity> _contentById = {};
  final Map<String, AkHotelRateItemEntity> _rateById = {};
  String _currency = 'INR';
  String _locationName = '';
  int _contentTotal = 0;
  bool _contentLoading = false;
  bool _rateCompleted = false;
  bool _initialLoading = true;
  String? _error;
  int _ratePollCount = 0;
  bool _rateTimedOut = false;

  bool _isFilterApplied = false;
  Map<String, dynamic> _activeFilters = {};

  static const _maxAutoContentPages = 12;

  @override
  void initState() {
    super.initState();
    _locationName = widget.locationName;
    _scrollController.addListener(_onScroll);
    _autoLoadContentUntilMerged();
    _pollRate();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _retrySearch() {
    setState(() {
      _error = null;
      _rateTimedOut = false;
      _ratePollCount = 0;
    });
    if (_contentById.isEmpty) _autoLoadContentUntilMerged();
    if (!_rateCompleted) _pollRate();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (!_contentLoading && _contentById.length < _contentTotal) {
        _loadNextContentPage();
      }
    }
  }

  /// Content and Rate rarely price the same hotels on their first page —
  /// they're independent, differently-ordered providers ("the two sets
  /// barely overlap at first"). Scroll-triggered pagination alone can't
  /// break that deadlock: with zero merged hotels there's no ListView to
  /// scroll, so nothing would ever request page 2. This keeps auto-pulling
  /// Content pages (bounded, so it can't runaway) until something merges,
  /// content is exhausted, or Rate finishes — after that, scrolling drives
  /// further pages as normal.
  Future<void> _autoLoadContentUntilMerged() async {
    int pagesLoaded = 0;
    while (mounted && pagesLoaded < _maxAutoContentPages) {
      await _loadNextContentPage();
      pagesLoaded++;
      if (!mounted) return;
      if (_mergedHotels.isNotEmpty) return;
      if (_error != null) return;
      if (_contentTotal > 0 && _contentById.length >= _contentTotal) return;
      if (_rateCompleted) return;
      // Pure throttle between page requests — no documented backend
      // rate-limit requires it, so keep it short rather than adding dead
      // time on top of each round trip while nothing has merged yet.
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> _loadNextContentPage() async {
    if (_contentLoading) return;
    setState(() => _contentLoading = true);

    final offset = _contentById.isEmpty ? -1 : _contentById.length;
    final result = await sl<AkHotelResultContentUseCase>().call(
      AkHotelResultContentRequestEntity(
        searchId: widget.searchId,
        searchTracingKey: widget.searchTracingKey,
        limit: 50,
        offset: offset,
      ),
    );

    if (!mounted) return;

    if (result is DataSuccess<AkHotelResultContentEntity>) {
      final data = result.data!;
      for (final h in data.hotels) {
        _contentById[h.id] = h;
      }
      setState(() {
        _contentTotal = data.total;
        if (data.locationName.isNotEmpty) _locationName = data.locationName;
        _contentLoading = false;
        _initialLoading = false;
      });
    } else {
      setState(() {
        _contentLoading = false;
        _initialLoading = false;
        if (_contentById.isEmpty) _error = 'Could not load hotels. Please try again.';
      });
    }
  }

  Future<void> _pollRate() async {
    while (mounted && !_rateCompleted && _ratePollCount < _maxRatePolls) {
      _ratePollCount++;
      final result = await sl<AkHotelResultRateUseCase>().call(
        AkHotelResultRateRequestEntity(searchId: widget.searchId, searchTracingKey: widget.searchTracingKey),
      );

      if (!mounted) return;

      if (result is DataSuccess<AkHotelResultRateEntity>) {
        final data = result.data!;
        for (final h in data.hotels) {
          _rateById[h.id] = h;
        }
        setState(() {
          _currency = data.currency.isNotEmpty ? data.currency : _currency;
          _rateCompleted = data.isCompleted;
          _initialLoading = false;
        });
      } else {
        // A transient rate-poll failure isn't fatal — content-only cards
        // just won't have a price yet; keep polling.
        break;
      }

      if (!_rateCompleted) {
        // Rate is a cumulative poll (each response already contains every
        // price resolved so far), so polling faster only surfaces prices
        // sooner — it can't skip or duplicate data. Most suppliers price
        // within the first few seconds, so poll tightly at first to get the
        // first hotel cards on screen fast, then back off so a slow search
        // doesn't hammer the API while it finishes in the background.
        final delay = _ratePollCount <= 6
            ? const Duration(milliseconds: 1200)
            : const Duration(seconds: 3);
        await Future.delayed(delay);
      }
    }

    if (mounted && !_rateCompleted && _ratePollCount >= _maxRatePolls) {
      setState(() => _rateTimedOut = true);
    }
  }

  List<HotelUiModel> get _mergedHotels {
    final merged = <HotelUiModel>[];
    for (final entry in _contentById.entries) {
      final rate = _rateById[entry.key];
      if (rate == null) continue;
      merged.add(_toUiModel(entry.value, rate));
    }
    return merged;
  }

  /// Same client-side filtering the old tbo-hotel listing screen applied
  /// (min/max price, star rating, amenities) — extended to also honor the
  /// drawer's Refundable/meal-plan fields since that data is available here
  /// (the old TBO screen sent those to the backend instead; this flow has
  /// no server-side hotel filter wired up yet, so everything is client-side).
  List<HotelUiModel> _applyFilters(List<HotelUiModel> hotels) {
    var result = hotels;
    final f = _activeFilters;

    final minPrice = f['min_price'];
    final maxPrice = f['max_price'];
    final starRating = f['star_rating'];
    final amenities = f['amenities'];
    final refundableOnly = f['Refundable'] == true;
    final mealType = f['MealType'];

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
      final required = amenities.map((a) => a.toString().toLowerCase()).toList();
      result = result.where((h) {
        final facilityText = h.facilities.join(' ').toLowerCase();
        return required.every((a) => facilityText.contains(a));
      }).toList();
    }
    if (refundableOnly) {
      result = result.where((h) => h.isRefundable).toList();
    }
    if (mealType != null && mealType != 'All') {
      result = result.where((h) => h.mealType.toLowerCase().contains(mealType.toString().toLowerCase())).toList();
    }

    return result;
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() {
      _isFilterApplied = true;
      _activeFilters = filters;
    });
  }

  void _onClearFilters() {
    setState(() {
      _isFilterApplied = false;
      _activeFilters = {};
    });
  }

  HotelUiModel _toUiModel(AkHotelContentItemEntity c, AkHotelRateItemEntity r) {
    final image = c.heroImage.isNotEmpty ? c.heroImage : (c.images.isNotEmpty ? c.images.first : '');
    return HotelUiModel(
      image: image,
      hotelName: c.name,
      address: c.address,
      price: '${CurrencyConverter.getSymbol(_currency)}${r.total.toStringAsFixed(0)}',
      numericPrice: r.total,
      taxes: '${CurrencyConverter.getSymbol(_currency)}${r.taxes.toStringAsFixed(0)}',
      rating: c.starRating.round().clamp(0, 5),
      roomInfo: '',
      description: '',
      images: c.images,
      currency: _currency,
      originalPrice: r.baseRate,
      hotelCode: c.id,
      bookingCode: r.provider,
      isRefundable: r.isRefundable,
      mealType: r.freeBreakfast ? 'Breakfast Included' : '',
      facilities: c.facilities.map((f) => f.name).toList(),
      cityName: _locationName,
      countryName: c.countryCode,
    );
  }

  void _navigateToDetail(HotelUiModel hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelDetailScreen(
          searchId: widget.searchId,
          searchTracingKey: widget.searchTracingKey,
          hotelId: hotel.hotelCode,
          hotelName: hotel.hotelName,
          priceProvider: hotel.bookingCode,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          adults: widget.adults,
          children: widget.children,
          nationality: widget.nationality,
          rooms: widget.rooms,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      drawer: HotelFilterDrawer(
        onFiltersApplied: _onFiltersApplied,
        onClearFilters: _onClearFilters,
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
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.hotel, size: 35),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      floatingActionButton: _buildFilterBadge(),
    );
  }

  Widget? _buildFilterBadge() {
    if (!_isFilterApplied) return null;
    return FloatingActionButton.small(
      onPressed: _onClearFilters,
      backgroundColor: _blue,
      tooltip: 'Clear filters',
      child: Icon(Icons.filter_alt, size: context.iconSmall, color: Colors.white),
    );
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return const HotelLoadingIndicator();
    }

    if (_error != null && _mergedHotels.isEmpty) {
      return Center(
        child: Padding(
          padding: context.horizontalPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: context.iconLarge * 2, color: Colors.grey.shade400),
              SizedBox(height: context.gapLarge),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: context.gapLarge),
              ElevatedButton(onPressed: _retrySearch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final hotels = _applyFilters(_mergedHotels);

    if (_mergedHotels.isEmpty) {
      if (_rateTimedOut) {
        return Center(
          child: Padding(
            padding: context.horizontalPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_disabled_outlined, size: context.iconLarge * 2, color: Colors.grey.shade400),
                SizedBox(height: context.gapLarge),
                Text(
                  'This search is taking longer than usual to price any hotels.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: context.bodyMedium),
                ),
                SizedBox(height: context.gapLarge),
                ElevatedButton(onPressed: _retrySearch, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }
      return const HotelLoadingIndicator();
    }

    if (hotels.isEmpty) {
      return Center(
        child: Padding(
          padding: context.horizontalPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_alt_off_outlined, size: context.iconLarge * 2, color: Colors.grey.shade400),
              SizedBox(height: context.gapLarge),
              Text(
                'No hotels match your filters',
                style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
              ),
              SizedBox(height: context.gapLarge),
              ElevatedButton(onPressed: _onClearFilters, child: const Text('Clear Filters')),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: context.scrollPhysics,
      padding: context.horizontalPadding.copyWith(
        top: context.gapMedium,
        bottom: context.gapLarge,
      ),
      itemCount: hotels.length + (_contentById.length < _contentTotal || !_rateCompleted ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= hotels.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: context.gapMedium),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
              ),
            ),
          );
        }
        return HotelCard(hotel: hotels[index], onSelectRoom: () => _navigateToDetail(hotels[index]));
      },
    );
  }
}
