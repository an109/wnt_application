import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/hotel_loading_indicator.dart';
import '../../../../core/error/data_state.dart';
import '../../../Hotel/Filter_drawer/filter_drawer.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';
import '../../../Hotel_api/presentation/screen/hotel_listing.dart' show HotelCard;
import '../../../AKHotelDetailContent/domain/entity/AKHotelDetailContent_entity.dart';
import '../../../AKHotelDetailContent/domain/usecase/AKHotelDetailContent_usecase.dart';
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
  final TextEditingController _searchController = TextEditingController();
  // Client-side only: narrows the hotels already loaded from Content+Rate
  // by name/address. It cannot surface a hotel that never made it into
  // _mergedHotels in the first place (see _applySearch's doc comment).
  String _searchQuery = '';

  final Map<String, AkHotelContentItemEntity> _contentById = {};
  // Content's lower-detail `curatedHotels` sibling list, kept in its own map
  // so it can never perturb `_contentById.length` vs `_contentTotal` (the
  // existing pagination-completion check below) — see
  // AkHotelResultContentEntity.curatedHotels for why this list exists at
  // all (the exact hotel a property-type search targets, e.g. "Velvet
  // Revive Munnar", is frequently only found here, never in `hotels`).
  final Map<String, AkHotelContentItemEntity> _curatedById = {};
  final Map<String, AkHotelRateItemEntity> _rateById = {};
  // curatedHotels rows never carry heroImage/images at all — Content's own
  // sparse shape for that list, not a parsing gap (see
  // AkHotelContentItemModel.fromCuratedJson) — so the pinned "hotel you
  // actually searched for" card would otherwise show no photo, ever. Lazily
  // backfilled from Hotel Content (the same call the detail screen already
  // uses) the moment such a card is about to render; keyed by hotel id so
  // each one is only ever fetched once.
  final Map<String, String> _backfilledImages = {};
  final Set<String> _imageBackfillAttempted = {};
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
    _searchController.dispose();
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
      for (final h in data.curatedHotels) {
        // Never overwrite a richer `hotels` entry with the sparse curated
        // shape — this map is purely a fallback for ids `hotels` never has.
        if (!_contentById.containsKey(h.id)) _curatedById[h.id] = h;
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

  /// True if [hotelName] looks like the place/hotel the user actually typed
  /// into the destination field ([AkHotelResultsScreen.locationName],
  /// e.g. "Zostel Kochi"). Deliberately loose (substring, either direction,
  /// case-insensitive) so a slightly different capitalisation/suffix
  /// between what Autosuggest returned and what Content names the hotel
  /// still counts as a match. A generic city search (locationName == "Kochi")
  /// essentially never matches a hotel's own name, so this only ever kicks
  /// in for a property-style search — it doesn't reorder a normal city list.
  bool _matchesSearchedName(String hotelName) {
    final target = widget.locationName.trim().toLowerCase();
    final name = hotelName.trim().toLowerCase();
    if (target.isEmpty || name.isEmpty) return false;
    return name.contains(target) || target.contains(name);
  }

  /// Queues a one-shot Hotel Content fetch to backfill [item]'s missing
  /// photo. Called from [_mergedHotels] for every hotel that's actually
  /// about to render a card — curated or not — but is a cheap no-op the
  /// instant it already has a heroImage/images, so it only ever fetches for
  /// the ones that genuinely need it (which is *every* curatedHotels row,
  /// see AkHotelContentItemModel.fromCuratedJson, and occasionally a plain
  /// `hotels` row Content itself sent with no photo). It's never called for
  /// rows that never make it onto the merged list, so this can't balloon
  /// into fetching content for the much larger, mostly-unshown
  /// curatedHotels list. Safe to call from a getter used during build: it
  /// only ever mutates state, if at all, from the post-frame callback,
  /// never synchronously.
  void _scheduleImageBackfill(AkHotelContentItemEntity item) {
    if (item.heroImage.isNotEmpty || item.images.isNotEmpty) return;
    if (_backfilledImages.containsKey(item.id)) return;
    if (!_imageBackfillAttempted.add(item.id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _backfillHotelImage(item.id));
  }

  Future<void> _backfillHotelImage(String hotelId) async {
    if (!mounted) return;
    // Best-effort — Hotel Content wants the priced provider, but a curated
    // match that hasn't been priced yet has none. Per the API's own
    // behaviour, a wrong/missing provider still gets served *some*
    // provider's content rather than failing outright, so an empty string
    // here is safe, not a guaranteed miss.
    final priceProvider = _rateById[hotelId]?.provider ?? '';
    final result = await sl<AkHotelDetailContentUseCase>().call(
      AkHotelDetailContentRequestEntity(
        searchId: widget.searchId,
        hotelId: hotelId,
        priceProvider: priceProvider,
      ),
    );
    if (!mounted) return;
    if (result is DataSuccess<AkHotelDetailContentEntity>) {
      final data = result.data!;
      final image = data.heroImage.isNotEmpty
          ? data.heroImage
          : (data.images.isNotEmpty ? data.images.first : '');
      if (image.isNotEmpty) {
        setState(() => _backfilledImages[hotelId] = image);
      }
    }
    // A failure here just leaves the card on its placeholder — already
    // recorded in _imageBackfillAttempted, so it won't retry every rebuild.
  }

  /// [AkHotelContentItemEntity.heroImage]/[images], with a backfilled photo
  /// (see [_scheduleImageBackfill]) taking priority once one arrives.
  String _resolveImage(AkHotelContentItemEntity c) {
    final backfilled = _backfilledImages[c.id];
    if (backfilled != null) return backfilled;
    return c.heroImage.isNotEmpty ? c.heroImage : (c.images.isNotEmpty ? c.images.first : '');
  }

  List<HotelUiModel> get _mergedHotels {
    // Two buckets, always rendered in this order, so the hotel the user
    // actually searched for never requires scrolling to find — whether it
    // arrived in Content's `hotels` list or its `curatedHotels` sibling
    // (see AkHotelResultContentEntity.curatedHotels), and whether or not
    // the in-page search bar is being used.
    final matched = <HotelUiModel>[];
    final rest = <HotelUiModel>[];

    for (final entry in _curatedById.entries) {
      final rate = _rateById[entry.key];
      final isMatch = _matchesSearchedName(entry.value.name);
      if (rate == null) {
        // Only the actual searched-for match is worth showing before it's
        // priced; every other curated hotel waits for Rate like normal.
        if (isMatch) {
          _scheduleImageBackfill(entry.value);
          matched.add(_toPendingUiModel(entry.value));
        }
        continue;
      }
      // Every curated row that actually renders gets its own backfill
      // attempt, not just the pinned match — curatedHotels never carries
      // image data at all (see _scheduleImageBackfill's doc comment), so
      // any of these left un-backfilled would show no photo, ever.
      _scheduleImageBackfill(entry.value);
      (isMatch ? matched : rest).add(_toUiModel(entry.value, rate));
    }
    for (final entry in _contentById.entries) {
      final rate = _rateById[entry.key];
      if (rate == null) continue;
      // No-ops instantly for a hotel that already has a real heroImage —
      // only the ones Content genuinely sent with none actually fetch
      // anything, so this is cheap for the common case.
      _scheduleImageBackfill(entry.value);
      final model = _toUiModel(entry.value, rate);
      (_matchesSearchedName(entry.value.name) ? matched : rest).add(model);
    }

    return [...matched, ...rest];
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

  /// Narrows an already-merged, already-filtered hotel list by name/address.
  /// Purely client-side over what's currently loaded — it can only find a
  /// hotel that has *already* made it into [_mergedHotels]. Curated
  /// (exact-match) hotels appear there even before Rate prices them, but a
  /// hotel Content never returned at all (in `hotels` or `curatedHotels`)
  /// for this search still can't be found here — no amount of client-side
  /// text filtering can recover data the API never sent.
  List<HotelUiModel> _applySearch(List<HotelUiModel> hotels) {
    if (_searchQuery.isEmpty) return hotels;
    return hotels
        .where((h) =>
            h.hotelName.toLowerCase().contains(_searchQuery) ||
            h.address.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
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
    final image = _resolveImage(c);
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

  /// A curated (exact-match) hotel Content already resolved but Rate hasn't
  /// priced yet — possibly never will, since Rate is a separate supplier
  /// feed. `bookingCode: ''` marks it as not-yet-bookable; [_navigateToDetail]
  /// checks that before opening the detail screen (Hotel Content there
  /// needs a real `priceProvider` in its query string).
  HotelUiModel _toPendingUiModel(AkHotelContentItemEntity c) {
    final image = _resolveImage(c);
    return HotelUiModel(
      image: image,
      hotelName: c.name,
      address: c.address,
      price: _rateTimedOut ? 'Price unavailable' : 'Fetching price…',
      numericPrice: 0,
      taxes: '',
      rating: c.starRating.round().clamp(0, 5),
      roomInfo: '',
      description: '',
      images: c.images,
      currency: _currency,
      originalPrice: 0,
      hotelCode: c.id,
      bookingCode: '',
      isRefundable: false,
      mealType: '',
      facilities: c.facilities.map((f) => f.name).toList(),
      cityName: _locationName,
      countryName: c.countryCode,
    );
  }

  void _navigateToDetail(HotelUiModel hotel) {
    if (hotel.bookingCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still fetching live pricing for this hotel — try again in a moment.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
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
        title: _buildAppBarSearchField(),
        titleSpacing: context.gapSmall,
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

  /// Replaces the old centred logo title — the app bar itself is now the
  /// search box, filtering whatever's already loaded on this screen.
  Widget _buildAppBarSearchField() {
    return Container(
      height: context.h(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(fontSize: context.bodyMedium, color: const Color(0xFF071638)),
        decoration: InputDecoration(
          hintText: 'Search hotels by name',
          hintStyle: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, size: context.iconSmall, color: Colors.grey.shade500),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, size: context.iconSmall, color: Colors.grey.shade500),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: context.h(10)),
        ),
      ),
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

    final searchedHotels = _applySearch(hotels);

    if (searchedHotels.isEmpty) {
      return Center(
        child: Padding(
          padding: context.horizontalPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: context.iconLarge * 2, color: Colors.grey.shade400),
              SizedBox(height: context.gapLarge),
              Text(
                'No hotels match "${_searchController.text.trim()}"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: context.titleLarge, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
              ),
              SizedBox(height: context.gapSmall),
              Text(
                'Only hotels already loaded on this screen are searched here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: context.bodyMedium, color: Colors.grey.shade600),
              ),
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
      // No "load more" spinner while a search is active — pagination keeps
      // pulling more Content pages in the background regardless, but the
      // spinner implied *this* filtered list would grow, which it may not.
      itemCount: searchedHotels.length +
          (_searchQuery.isEmpty && (_contentById.length < _contentTotal || !_rateCompleted) ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= searchedHotels.length) {
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
        return HotelCard(hotel: searchedHotels[index], onSelectRoom: () => _navigateToDetail(searchedHotels[index]));
      },
    );
  }
}
