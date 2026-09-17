import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/hotel_loading_indicator.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Hotel_api/domain/entities/hotel_ui_entity.dart';
import '../../../AKHotelDetailContent/domain/entity/AKHotelDetailContent_entity.dart';
import '../../../AKHotelDetailContent/domain/usecase/AKHotelDetailContent_usecase.dart';
import '../../../AKHotelResultContent/domain/entity/AKHotelResultContent_entity.dart';
import '../../../AKHotelResultContent/domain/usecase/AKHotelResultContent_usecase.dart';
import '../../../AKHotelResultRate/domain/entity/AKHotelResultRate_entity.dart';
import '../../../AKHotelResultRate/domain/usecase/AKHotelResultRate_usecase.dart';
import '../../../AKHotelSearchInit/domain/entity/AKHotelSearchInit_entity.dart';
import '../widgets/ak_hotel_bottom_bar.dart';
import '../widgets/ak_hotel_client_filters.dart';
import '../widgets/ak_hotel_collections_section.dart';
import '../widgets/ak_hotel_recommended_card.dart';
import '../widgets/ak_hotel_section_card.dart';
import '../widgets/ak_hotel_sort_sheet.dart';
import '../widgets/ak_hotel_top_bar.dart';
import 'ak_hotel_detail_screen.dart';
import 'ak_hotel_filter_screen.dart';
import 'ak_hotel_view_all_screen.dart';

/// Results screen for the Akbar Hotels flow: Content (static hotel info)
/// and Rate (pricing) are independent, slower-resolving providers, so both
/// are fetched in parallel and merged by hotel id as each poll comes back —
/// a hotel only becomes a visible card once it has both. Reuses the
/// existing [HotelUiModel] presentational model from Hotel_api (only the
/// data source is new); rendered as horizontal-scroll "Match" /
/// "Recommended Hotel" / "Near by" sections of [AkHotelSectionCard]s, each
/// with its own "View all" into [AkHotelViewAllScreen].
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
  static const _blue = AppColors.AppBlue;
  static const _pageBg = AppColors.white;
  static const _maxRatePolls = 20;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Purely additive, client-side "Sort" from the new bottom bar — reorders
  // whatever's already been fetched/filtered/searched, never re-queries.
  AkHotelSortOption? _sortOption;

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
  // True only while _pollRate's loop is actually running. Distinct from
  // _rateCompleted (which only means "the provider said done") — this also
  // flips false when polling gives up for any other reason (hits
  // _maxRatePolls, or a transient poll failure breaks the loop), so nothing
  // that only checks "rate is done" is left waiting forever on a poll that
  // has actually stopped. See the "Match Result" skeleton below, which used
  // to gate on `!_rateCompleted` alone and would shimmer forever once
  // polling gave up without ever reaching `completed`.
  bool _ratePollingActive = false;

  bool _isFilterApplied = false;
  Map<String, dynamic> _activeFilters = {};
  // True only while _autoLoadContentForMatch is actively paging looking for
  // a match — drives the "Match" section's skeleton placeholder so that
  // section isn't just silently absent while it's still being looked for.
  bool _matchSearchInProgress = false;

  static const _maxAutoContentPages = 12;

  @override
  void initState() {
    super.initState();
    _locationName = widget.locationName;
    // Sections are horizontal carousels now, not one long vertical list, so
    // "scrolled near the bottom" no longer means "needs more data" — it kept
    // firing almost continuously (see the removed _onScroll) because a
    // handful of short rows barely scrolls at all. All Content pagination
    // now happens proactively, right after search, bounded, and once —
    // never re-triggered by scrolling.
    _autoLoadContentUntilMerged().then((_) => _autoLoadContentForMatch());
    _pollRate();
    CurrencyConverter.currencyListenable.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    CurrencyConverter.currencyListenable.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _retrySearch() {
    setState(() {
      _error = null;
      _rateTimedOut = false;
      _ratePollCount = 0;
    });
    if (_contentById.isEmpty) {
      _autoLoadContentUntilMerged().then((_) => _autoLoadContentForMatch());
    } else if (_matchedHotels.isEmpty) {
      _autoLoadContentForMatch();
    }
    if (!_rateCompleted) _pollRate();
  }

  /// Content and Rate rarely price the same hotels on their first page —
  /// they're independent, differently-ordered providers ("the two sets
  /// barely overlap at first"). This keeps auto-pulling Content pages
  /// (bounded, so it can't runaway) until something merges, content is
  /// exhausted, or Rate finishes — purely so the first section has
  /// *something* to show as fast as possible. See [_autoLoadContentForMatch]
  /// for the follow-up phase that keeps looking specifically for the hotel
  /// the user searched for.
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

  /// Runs right after [_autoLoadContentUntilMerged] settles. That first pass
  /// stops the instant *anything* merges — usually a "Near by"/"Recommended"
  /// hotel, since the property the user actually searched for often only
  /// shows up in a later page's `curatedHotels` (see
  /// AkHotelResultContentEntity.curatedHotels). Left alone, "Match" would
  /// then only ever appear whenever the user happened to scroll far enough
  /// to ask for another page — popping in and reflowing everything already
  /// on screen long after the other sections had settled. This keeps
  /// quietly paging a little further, purely to give that match a real
  /// chance to turn up. Bounded and self-stopping: most searches (a plain
  /// city, not a specific property) have no match at all, so this must not
  /// keep paging forever hunting for one that was never coming.
  Future<void> _autoLoadContentForMatch() async {
    if (_matchedHotels.isNotEmpty) return; // nothing to look for
    setState(() => _matchSearchInProgress = true);
    try {
      const maxExtraPages = 4;
      int extraPagesLoaded = 0;
      while (mounted &&
          extraPagesLoaded < maxExtraPages &&
          _matchedHotels.isEmpty &&
          _error == null &&
          !(_contentTotal > 0 && _contentById.length >= _contentTotal)) {
        await _loadNextContentPage();
        extraPagesLoaded++;
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } finally {
      if (mounted) setState(() => _matchSearchInProgress = false);
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
    setState(() => _ratePollingActive = true);
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
    if (mounted) setState(() => _ratePollingActive = false);
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
  /// photo — a cheap no-op the instant it already has a heroImage/images, so
  /// it only ever fetches for the ones that genuinely need it (which is
  /// *every* curatedHotels row, see AkHotelContentItemModel.fromCuratedJson,
  /// and occasionally a plain `hotels` row Content itself sent with no
  /// photo). Called from [_buildSection]'s itemBuilder, i.e. only for a
  /// hotel whose card actually gets built (the visible carousel window plus
  /// Flutter's own cache-ahead) — NOT from [_matchedHotels]/[_restHotels],
  /// which run many times per build and would otherwise queue a Content
  /// call for every photo-less hotel across every section (Match, Near by,
  /// Recommended) the instant the screen renders, most of them still
  /// off-screen. Safe to call during build either way: it only ever mutates
  /// state, if at all, from the post-frame callback, never synchronously.
  void _scheduleImageBackfill(AkHotelContentItemEntity item) {
    if (item.heroImage.isNotEmpty || item.images.isNotEmpty) return;
    if (_backfilledImages.containsKey(item.id)) return;
    if (!_imageBackfillAttempted.add(item.id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _backfillHotelImage(item.id));
  }

  /// Looks up the raw Content entity behind a [HotelUiModel] (by its
  /// [HotelUiModel.hotelCode], the same id both maps are keyed by) so
  /// [_buildSection] can schedule a backfill per-card without needing its
  /// own copy of the Content data.
  void _scheduleImageBackfillForHotel(String hotelCode) {
    final item = _curatedById[hotelCode] ?? _contentById[hotelCode];
    if (item != null) _scheduleImageBackfill(item);
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

  /// The hotel(s) the user actually searched for (see
  /// [_matchesSearchedName]'s doc comment — this only ever kicks in for a
  /// property-style search, e.g. "Zostel Kochi"). Surfaced on its own as the
  /// results screen's "Match" section.
  List<HotelUiModel> get _matchedHotels {
    final matched = <HotelUiModel>[];
    for (final entry in _curatedById.entries) {
      if (!_matchesSearchedName(entry.value.name)) continue;
      final rate = _rateById[entry.key];
      // Backfill is scheduled lazily from _buildSection's itemBuilder now
      // (only for cards actually built), not here — this getter runs many
      // times per build (see _mergedHotels' callers), so scheduling it here
      // fired a Content call for every matching hotel on every build,
      // whether or not its card ever rendered.
      matched.add(rate == null ? _toPendingUiModel(entry.value) : _toUiModel(entry.value, rate));
    }
    for (final entry in _contentById.entries) {
      final rate = _rateById[entry.key];
      if (rate == null) continue;
      if (!_matchesSearchedName(entry.value.name)) continue;
      matched.add(_toUiModel(entry.value, rate));
    }
    return matched;
  }

  /// Every other loaded hotel — i.e. [_mergedHotels] minus [_matchedHotels].
  List<HotelUiModel> get _restHotels {
    final rest = <HotelUiModel>[];
    for (final entry in _curatedById.entries) {
      if (_matchesSearchedName(entry.value.name)) continue;
      final rate = _rateById[entry.key];
      if (rate == null) continue;
      rest.add(_toUiModel(entry.value, rate));
    }
    for (final entry in _contentById.entries) {
      final rate = _rateById[entry.key];
      if (rate == null) continue;
      if (_matchesSearchedName(entry.value.name)) continue;
      rest.add(_toUiModel(entry.value, rate));
    }
    return rest;
  }

  /// [_matchedHotels] followed by [_restHotels] — kept as a single getter
  /// (same shape as before this screen grew separate "Match"/"Recommended
  /// Hotel"/"Near by" sections) since the loading/error/empty-state and
  /// pagination checks below only ever care about the combined count.
  List<HotelUiModel> get _mergedHotels => [..._matchedHotels, ..._restHotels];

  /// Same client-side filtering the old tbo-hotel listing screen applied
  /// (min/max price, star rating, amenities) — extended to also honor the
  /// drawer's Refundable/meal-plan fields since that data is available here
  /// (the old TBO screen sent those to the backend instead; this flow has
  /// no server-side hotel filter wired up yet, so everything is client-side).
  List<HotelUiModel> _applyFilters(List<HotelUiModel> hotels) =>
      applyAkHotelClientFilters(hotels, _activeFilters);

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

  /// Replaces the old [HotelFilterDrawer] with a full screen (Figma
  /// reference) — same `onFiltersApplied`/`onClearFilters` contract, so
  /// nothing about how filtering actually works changes, only how it's
  /// opened. [_mergedHotels] (every hotel loaded so far, before the active
  /// filters narrow it) backs the real per-option counts the screen shows.
  void _openFilterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelFilterScreen(
          initialFilters: _activeFilters,
          hotels: _mergedHotels,
          onApply: _onFiltersApplied,
          onClear: _onClearFilters,
        ),
      ),
    );
  }

  // HotelUiModel _toUiModel(AkHotelContentItemEntity c, AkHotelRateItemEntity r) {
  //   final image = _resolveImage(c);
  //   return HotelUiModel(
  //     image: image,
  //     hotelName: c.name,
  //     address: c.address,
  //     price: '${CurrencyConverter.getSymbol(_currency)}${r.total.toStringAsFixed(0)}',
  //     numericPrice: r.total,
  //     taxes: '${CurrencyConverter.getSymbol(_currency)}${r.taxes.toStringAsFixed(0)}',
  //     rating: c.starRating.round().clamp(0, 5),
  //     roomInfo: '',
  //     description: '',
  //     images: c.images,
  //     currency: _currency,
  //     originalPrice: r.baseRate,
  //     hotelCode: c.id,
  //     bookingCode: r.provider,
  //     isRefundable: r.isRefundable,
  //     mealType: r.freeBreakfast ? 'Breakfast Included' : '',
  //     facilities: c.facilities.map((f) => f.name).toList(),
  //     cityName: _locationName,
  //     countryName: c.countryCode,
  //   );
  // }
  HotelUiModel _toUiModel(AkHotelContentItemEntity c, AkHotelRateItemEntity r) {
    final image = _resolveImage(c);
    // Get current currency from CurrencyConverter
    final currentCurrency = CurrencyConverter.getPreferredCurrency();

    // Convert price from _currency to currentCurrency
    final convertedPrice = CurrencyConverter.convert(
      amount: r.total,
      fromCurrency: _currency,
      toCurrency: currentCurrency,
    );

    return HotelUiModel(
      image: image,
      hotelName: c.name,
      address: c.address,
      price: CurrencyConverter.format(convertedPrice, currentCurrency),
      numericPrice: convertedPrice,
      taxes: CurrencyConverter.format(
        CurrencyConverter.convert(
          amount: r.taxes,
          fromCurrency: _currency,
          toCurrency: currentCurrency,
        ),
        currentCurrency,
      ),
      rating: c.starRating.round().clamp(0, 5),
      roomInfo: '',
      description: '',
      images: c.images,
      currency: currentCurrency, // Store converted currency
      originalPrice: CurrencyConverter.convert(
        amount: r.baseRate,
        fromCurrency: _currency,
        toCurrency: currentCurrency,
      ),
      hotelCode: c.id,
      bookingCode: r.provider,
      isRefundable: r.isRefundable,
      mealType: r.freeBreakfast ? 'Breakfast Included' : '',
      facilities: c.facilities.map((f) => f.name).toList(),
      cityName: _locationName,
      countryName: c.countryCode,
    );
  }

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
      key: _scaffoldKey,
      backgroundColor: _pageBg,
      body: Column(
        children: [
          AkHotelTopBar(
            locationName: _locationName,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            adults: widget.adults,
            children: widget.children,
            roomCount: widget.rooms.length,
            onBack: () => Navigator.of(context).maybePop(),
            onEdit: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
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

    // The sectioned layout below re-derives matched/rest separately (same
    // _applyFilters pipeline `hotels` above already ran, just kept apart) so
    // "Match" and "Near by" can be rendered as their own rows.
    final matchedSection = _applyFilters(_matchedHotels);
    final restSection = _applyFilters(_restHotels);
    final recommendedSection = restSection.where((h) => h.rating == 5).toList();

    final sortedMatched = applyAkHotelSort(matchedSection, _sortOption);
    final sortedRecommended = applyAkHotelSort(recommendedSection, _sortOption);
    final sortedNearby = applyAkHotelSort(restSection, _sortOption);

    // Same top-rated hotels already on screen, just laid out as a photo
    // mosaic instead of a strip — never a separate/static data source.
    final collectionHotels = <String, HotelUiModel>{};
    for (final h in [...sortedMatched, ...sortedRecommended, ...sortedNearby]) {
      if (h.image.isEmpty && h.images.isEmpty) continue;
      collectionHotels.putIfAbsent(h.hotelCode, () => h);
    }
    final sortedCollections = collectionHotels.values.toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Stack(
      children: [
        ListView(
          controller: _scrollController,
          physics: context.scrollPhysics,
          padding: EdgeInsets.only(top: context.gapMedium, bottom: context.h(110)),
          children: [
            if (sortedMatched.isNotEmpty)
              _buildSection(title: 'Match Result', hotels: sortedMatched, showViewAll: false)
            // Keep showing "still looking" for as long as there's any real
            // chance a match still turns up — not just while
            // _autoLoadContentForMatch itself is actively paging. A hotel
            // whose *name* already matched can already be sitting in
            // _contentById/_curatedById waiting on Rate (which polls on its
            // own schedule, independent of the content search and often
            // takes far longer) — ending the skeleton the moment the
            // content search gives up made it vanish and then have the
            // real card pop in later, unannounced, once Rate finally priced
            // it. Gated on _ratePollingActive rather than !_rateCompleted so
            // this stops the moment Rate actually gives up polling (timeout
            // or a transient failure), instead of shimmering forever any
            // time Rate never reaches a literal "completed" status.
            else if (_matchSearchInProgress || _ratePollingActive)
              _buildMatchSkeletonSection(),
            SizedBox(height: context.h(6)),
            if (sortedNearby.isNotEmpty) _buildSection(title: 'Near by', hotels: sortedNearby),
            SizedBox(height: context.h(6)),
            if (sortedRecommended.isNotEmpty)
              _buildSection(
                title: 'Recommended Hotel',
                hotels: sortedRecommended,
                rowHeight: 85,
                cardBuilder: (hotel) => AkHotelRecommendedCard(hotel: hotel, onTap: () => _navigateToDetail(hotel)),
              ),
            SizedBox(height: context.h(6)),
            AkHotelCollectionsSection(
              hotels: sortedCollections.take(AkHotelCollectionsSection.minHotelsRequired).toList(),
              onSelect: _navigateToDetail,
            ),

          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AkHotelBottomBar(
            sortActive: _sortOption != null,
            filterActive: _isFilterApplied,
            onMapTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Map view coming soon'), duration: Duration(seconds: 2)),
            ),
            onSortTap: () => showAkHotelSortSheet(
              context: context,
              current: _sortOption,
              onSelected: (option) => setState(() => _sortOption = option),
            ),
            onFilterTap: _openFilterScreen,
            onAiTap: () => debugPrint('AI button tapped in AkHotelResultsScreen'),
          ),
        ),
      ],
    );
  }

  /// One "Title ... View all" row + its horizontal-scroll strip of
  /// [AkHotelSectionCard]s. "View all" only shows up once there's actually
  /// more to see than the strip's own preview.
  Widget _buildSection({
    required String title,
    required List<HotelUiModel> hotels,
    bool showViewAll = true,
    double rowHeight = 240,
    Widget Function(HotelUiModel hotel)? cardBuilder,
  }) {
    if (hotels.isEmpty) return const SizedBox.shrink();
    final viewAllVisible = showViewAll && hotels.length > 4;
    final buildCard = cardBuilder ?? (hotel) => AkHotelSectionCard(hotel: hotel, onTap: () => _navigateToDetail(hotel));

    return Padding(
      padding: EdgeInsets.only(bottom: context.gapMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gapLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
                if (viewAllVisible)
                  GestureDetector(
                    onTap: () => _openViewAll(title, hotels),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600, color: AppColors.AppBlue),
                        ),
                        Icon(Icons.chevron_right_rounded, size: context.w(15), color: AppColors.AppBlue),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.gapLarge),
          SizedBox(
            height: context.h(rowHeight),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: context.gapLarge),
              itemCount: hotels.length,
              separatorBuilder: (_, __) => SizedBox(width: context.gapMedium),
              itemBuilder: (context, index) {
                final hotel = hotels[index];
                // Only a card ListView.separated actually builds (visible +
                // Flutter's own cache-ahead) ever queues a backfill — see
                // _scheduleImageBackfill's doc comment for why this moved
                // here instead of the _matchedHotels/_restHotels getters.
                _scheduleImageBackfillForHotel(hotel.hotelCode);
                return buildCard(hotel);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Same header + row shape as [_buildSection], but for the moment before
  /// there's any real "Match" data yet — see [_autoLoadContentForMatch] and
  /// [_matchSearchInProgress].
  Widget _buildMatchSkeletonSection() {
    return Padding(
      padding: EdgeInsets.only(bottom: context.gapMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gapLarge),
            child: Text(
              'Match Result',
              style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w600, color: AppColors.navy),
            ),
          ),
          SizedBox(height: context.gapLarge),
          SizedBox(
            height: context.h(240),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: context.gapLarge),
              children: const [AkHotelSectionCardSkeleton()],
            ),
          ),
        ],
      ),
    );
  }

  void _openViewAll(String title, List<HotelUiModel> hotels) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelViewAllScreen(
          title: title,
          hotels: hotels,
          onSelectHotel: _navigateToDetail,
          locationName: _locationName,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          adults: widget.adults,
          children: widget.children,
          roomCount: widget.rooms.length,
        ),
      ),
    );
  }
}
