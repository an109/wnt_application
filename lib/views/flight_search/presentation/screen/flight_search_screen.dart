import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import '../../../../../injection_container.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/loadingScreen.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../domain/entities/flight_entity.dart';
import '../../domain/entities/flight_search_request_entity.dart';
import '../bloc/flight_search_bloc.dart';
import '../bloc/flight_search_event.dart';
import '../bloc/flight_search_state.dart';
import 'detail_popup.dart';
import 'filter_drawer.dart';

// ---------------------------------------------------------------------------
// Group model
// ---------------------------------------------------------------------------
class _FlightGroup {
  final FlightEntity primary;
  final List<FlightEntity> extras;
  final String key;

  _FlightGroup({required this.primary, required this.extras, required this.key});

  int get totalCount => 1 + extras.length;
}

// ---------------------------------------------------------------------------
// Offer model (MMT-style promo cards)
// ---------------------------------------------------------------------------
class _FlightOffer {
  final String title;
  final String code;
  final IconData icon;

  const _FlightOffer({
    required this.title,
    required this.code,
    required this.icon,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class FlightSearchScreen extends StatefulWidget {
  final String from;
  final String to;
  final String fromCode;
  final String toCode;
  final String fromAirport;
  final String toAirport;
  final DateTime? date;
  final int travellers;
  final int adults;
  final int children;
  final int infants;
  final String travelClass;
  final bool isRoundTrip;
  final DateTime? returnDate;

  const FlightSearchScreen({
    super.key,
    required this.from,
    required this.to,
    required this.fromCode,
    required this.toCode,
    required this.fromAirport,
    required this.toAirport,
    required this.date,
    required this.travellers,
    required this.adults,
    required this.children,
    required this.infants,
    required this.travelClass,
    required this.isRoundTrip,
    this.returnDate,
  });

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late FlightSearchBloc _flightSearchBloc;

  // filter & sort state
  String _selectedSort = "Recommended";
  RangeValues _priceRange = const RangeValues(0, 50000);
  double _maxPrice = 50000;
  double _minPrice = 0;
  Set<String> _selectedAirlines = {};
  Set<String> _selectedDepartureTimes = {};
  Set<String> _selectedArrivalTimes = {};
  bool _filterRefundable = false;
  bool _filterNonRefundable = false;

  // cached flight list for the drawer
  List<FlightEntity> _allFlights = [];

  // expanded groups
  final Set<String> _expandedGroups = {};

  bool _isApiCalled = false;
  int currentIndex = 0;

  // Horizontally scrollable date strip (MMT style)
  DateTime? _selectedDate;
  DateTime? _returnDate;
  final ScrollController _dateScrollController = ScrollController();
  bool _didInitialDateScroll = false;
  static const int _dateStripDays = 30;

  static const _sortOptions = [
    "Recommended",
    "Price: Low to High",
    "Price: High to Low",
    "Duration: Shortest",
    "Departure: Earliest",
  ];

  @override
  void initState() {
    super.initState();
    _flightSearchBloc = sl<FlightSearchBloc>();
    _selectedDate = widget.date != null
        ? DateUtils.dateOnly(widget.date!)
        : DateUtils.dateOnly(DateTime.now());
    _returnDate = widget.returnDate;
    _triggerFlightSearch();
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _flightSearchBloc.close();
    super.dispose();
  }

  void _triggerFlightSearch() {
    if (_isApiCalled) return;
    _isApiCalled = true;
    _flightSearchBloc.add(SearchFlightsEvent(_buildRequest()));
  }

  /// Re-run the search for a newly picked date from the date strip.
  void _onDateSelected(DateTime date) {
    final d = DateUtils.dateOnly(date);
    if (_selectedDate != null && DateUtils.isSameDay(d, _selectedDate!)) return;
    setState(() {
      _selectedDate = d;
      // Keep the return leg valid for round trips.
      if (widget.isRoundTrip &&
          _returnDate != null &&
          _returnDate!.isBefore(d)) {
        _returnDate = d;
      }
      // Reset filters so the fresh results are not over-filtered.
      _selectedAirlines = {};
      _selectedDepartureTimes = {};
      _selectedArrivalTimes = {};
      _filterRefundable = false;
      _filterNonRefundable = false;
      _expandedGroups.clear();
    });
    _flightSearchBloc.add(SearchFlightsEvent(_buildRequest()));
  }

  void _scrollSelectedDateIntoView() {
    if (_didInitialDateScroll || !_dateScrollController.hasClients) return;
    _didInitialDateScroll = true;
    final today = DateUtils.dateOnly(DateTime.now());
    final idx = (_selectedDate ?? today)
        .difference(today)
        .inDays
        .clamp(0, _dateStripDays - 1);
    final extent = context.w(72);
    final target = (idx * extent) - context.w(12);
    _dateScrollController.jumpTo(
      target.clamp(0.0, _dateScrollController.position.maxScrollExtent),
    );
  }

  FlightSearchRequestEntity _buildRequest() {
    final segments = <FlightSegmentEntity>[
      FlightSegmentEntity(
        origin: widget.fromCode,
        destination: widget.toCode,
        flightCabinClass: _getCabinClassInt(widget.travelClass),
        preferredDepartureTime: _formatDateForAPI(_selectedDate),
        preferredArrivalTime: _formatDateForAPI(_selectedDate),
      ),
    ];
    if (widget.isRoundTrip && _returnDate != null) {
      segments.add(FlightSegmentEntity(
        origin: widget.toCode,
        destination: widget.fromCode,
        flightCabinClass: _getCabinClassInt(widget.travelClass),
        preferredDepartureTime: _formatDateForAPI(_returnDate),
        preferredArrivalTime: _formatDateForAPI(_returnDate),
      ));
    }
    return FlightSearchRequestEntity(
      endUserIp: '122.161.72.69',
      adultCount: widget.adults,
      childCount: widget.children,
      infantCount: widget.infants,
      journeyType: widget.isRoundTrip ? 2 : 1,
      segments: segments,
    );
  }

  String _formatDateForAPI(DateTime? date) => date == null
      ? ''
      : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00';

  int _getCabinClassInt(String travelClass) {
    switch (travelClass.toLowerCase()) {
      case 'premium economy':
        return 3;
      case 'business':
        return 4;
      case 'first':
        return 5;
      default:
        return 2;
    }
  }

  // ---------------------------------------------------------------------------
  // Airline metadata derived from flights
  // ---------------------------------------------------------------------------
  Map<String, int> _buildAirlineCounts(List<FlightEntity> flights) {
    final map = <String, int>{};
    for (final f in flights) {
      final name = f.airlineName ?? 'Unknown';
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  Map<String, double> _buildAirlineMinPrices(List<FlightEntity> flights) {
    final map = <String, double>{};
    for (final f in flights) {
      final name = f.airlineName ?? 'Unknown';
      final price = (f.totalFare ?? 0).toDouble();
      if (!map.containsKey(name) || price < map[name]!) map[name] = price;
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // Filtering & sorting
  // ---------------------------------------------------------------------------
  List<FlightEntity> _applyFilters(List<FlightEntity> flights) {
    var result = List<FlightEntity>.from(flights);

    // price
    result = result
        .where((f) =>
            (f.totalFare ?? 0) >= _priceRange.start &&
            (f.totalFare ?? 0) <= _priceRange.end)
        .toList();

    // airlines – if none selected treat as "all"
    if (_selectedAirlines.isNotEmpty) {
      result = result
          .where((f) => _selectedAirlines.contains(f.airlineName ?? 'Unknown'))
          .toList();
    }

    // departure time slots
    if (_selectedDepartureTimes.isNotEmpty) {
      result = result.where((f) {
        final h = _hourOf(f.departureTime);
        return _selectedDepartureTimes.any((s) => _inSlot(h, s));
      }).toList();
    }

    // arrival time slots
    if (_selectedArrivalTimes.isNotEmpty) {
      result = result.where((f) {
        final h = _hourOf(f.arrivalTime);
        return _selectedArrivalTimes.any((s) => _inSlot(h, s));
      }).toList();
    }

    // sort
    switch (_selectedSort) {
      case "Price: Low to High":
        result.sort((a, b) => (a.totalFare ?? 0).compareTo(b.totalFare ?? 0));
        break;
      case "Price: High to Low":
        result.sort((a, b) => (b.totalFare ?? 0).compareTo(a.totalFare ?? 0));
        break;
      case "Duration: Shortest":
        result.sort((a, b) =>
            (int.tryParse(a.duration ?? '0') ?? 9999)
                .compareTo(int.tryParse(b.duration ?? '0') ?? 9999));
        break;
      case "Departure: Earliest":
        result.sort((a, b) =>
            (a.departureTime ?? '').compareTo(b.departureTime ?? ''));
        break;
    }

    return result;
  }

  int _hourOf(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return 0;
    try {
      return DateTime.parse(isoTime).hour;
    } catch (_) {
      return 0;
    }
  }

  bool _inSlot(int hour, String slot) {
    switch (slot) {
      case '05am-12pm':
        return hour >= 5 && hour < 12;
      case '12pm-6pm':
        return hour >= 12 && hour < 18;
      case '6pm-11pm':
        return hour >= 18 && hour < 23;
      case '11pm-05am':
        return hour >= 23 || hour < 5;
      default:
        return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Grouping
  // ---------------------------------------------------------------------------
  List<_FlightGroup> _groupFlights(List<FlightEntity> flights) {
    final map = <String, List<FlightEntity>>{};
    for (final f in flights) {
      final key =
          '${f.airlineName ?? ""}__${(f.totalFare ?? 0).toStringAsFixed(0)}';
      map.putIfAbsent(key, () => []).add(f);
    }
    return map.entries.map((e) {
      final sorted = e.value;
      return _FlightGroup(
        primary: sorted.first,
        extras: sorted.length > 1 ? sorted.sublist(1) : [],
        key: e.key,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Price / max init
  // ---------------------------------------------------------------------------
  void _updateMaxPrice(List<FlightEntity> flights) {
    if (flights.isEmpty) return;

    // Update cache immediately — no setState needed for a plain field.
    _allFlights = flights;

    final maxP = flights.fold<double>(
        0, (m, f) => (f.totalFare ?? 0) > m ? (f.totalFare ?? 0) : m);
    final minP = flights.fold<double>(double.infinity,
        (m, f) => (f.totalFare ?? 0) < m ? (f.totalFare ?? 0) : m);

    final newMax = maxP == 0 ? 50000.0 : maxP;
    final newMin = minP == double.infinity ? 0.0 : minP;

    // Nothing changed — skip the rebuild.
    if (newMax == _maxPrice && newMin == _minPrice && _selectedAirlines.isNotEmpty) return;

    // Defer setState to after the current build frame to avoid calling
    // setState() during a build, which triggers the assertion error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _maxPrice = newMax;
        _minPrice = newMin;
        _priceRange = RangeValues(newMin, newMax);
        if (_selectedAirlines.isEmpty) {
          _selectedAirlines =
              flights.map((f) => f.airlineName ?? 'Unknown').toSet();
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Open drawer with current state
  // ---------------------------------------------------------------------------
  void _openFilterDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onFilterApply(FlightFilterResult result) {
    setState(() {
      // Convert filter range from preferred currency back to INR
      final preferred = CurrencyConverter.getPreferredCurrency();
      _priceRange = RangeValues(
        CurrencyConverter.convert(
          amount: result.priceRange.start,
          fromCurrency: preferred,
          toCurrency: 'INR',
        ),
        CurrencyConverter.convert(
          amount: result.priceRange.end,
          fromCurrency: preferred,
          toCurrency: 'INR',
        ),
      );
      _selectedAirlines = result.selectedAirlines;
      _selectedDepartureTimes = result.selectedDepartureTimes;
      _selectedArrivalTimes = result.selectedArrivalTimes;
      _filterRefundable = result.refundable;
      _filterNonRefundable = result.nonRefundable;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return BlocProvider<FlightSearchBloc>(
      create: (_) => _flightSearchBloc,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildFilterDrawer(),
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: EdgeInsets.all(context.w(8)),
              child: Image.asset(
                "assets/images/wander_logo.png",
                height: context.h(35),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade50,
        body: BlocBuilder<FlightSearchBloc, FlightSearchState>(
          builder: (context, state) {
            if (state is FlightSearchLoading) {
              return ProfessionalLoadingScreen(
                searchParams: {
                  'fromAirport': widget.fromAirport,
                  'toAirport': widget.toAirport,
                  'departureDate': _selectedDate,
                  'returnDate': _returnDate,
                  'adults': widget.adults,
                  'children': widget.children,
                  'infants': widget.infants,
                  'class': widget.travelClass,
                  'isRoundTrip': widget.isRoundTrip,
                },
                onLoadingComplete: () {},
              );
            }
            if (state is FlightSearchError)
              return _buildErrorState(state.message);
            if (state is FlightSearchLoaded) {
              _updateMaxPrice(state.flights);
              return _buildMainContent(state.flights);
            }
            return _buildEmptyState();
          },
        ),
        bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    // Derive the API currency from any flight in the cached list.
    // This is the same currency that totalFare values (and _priceRange) are stored in.
    final apiCurrency = _allFlights.isNotEmpty
        ? (_allFlights.first.currency ?? 'INR')
        : 'INR';

    return FlightFilterDrawer(
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      currentPriceRange: _priceRange,
      currentSelectedAirlines: _selectedAirlines,
      currentSelectedDepartureTimes: _selectedDepartureTimes,
      currentSelectedArrivalTimes: _selectedArrivalTimes,
      currentRefundable: _filterRefundable,
      currentNonRefundable: _filterNonRefundable,
      airlineCounts: _buildAirlineCounts(_allFlights),
      airlineMinPrices: _buildAirlineMinPrices(_allFlights),
      onApply: _onFilterApply,
      apiCurrency: apiCurrency,
    );
  }

  Widget _buildMainContent(List<FlightEntity> flights) {
    final filtered = _applyFilters(flights);
    final groups = _groupFlights(filtered);
    return Column(
      children: [
        // _buildRouteSummary(filtered),
        _buildDateStrip(),
        _buildSortBar(),
        Expanded(child: _buildFlightList(groups, filtered.length, flights.length)),
      ],
    );
  }


  // ---------------------------------------------------------------------------
  // Horizontally scrollable date + day strip
  // ---------------------------------------------------------------------------
  Widget _buildDateStrip() {
    final today = DateUtils.dateOnly(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollSelectedDateIntoView(),
    );
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: context.h(6)),
      child: SizedBox(
        height: context.h(58),
        child: ListView.builder(
          controller: _dateScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.w(12)),
          itemCount: _dateStripDays,
          itemBuilder: (context, i) {
            final date = today.add(Duration(days: i));
            final selected =
                _selectedDate != null && DateUtils.isSameDay(date, _selectedDate!);
            return GestureDetector(
              onTap: () => _onDateSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: context.w(62),
                margin: EdgeInsets.symmetric(horizontal: context.w(4)),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xff1663F7) : Colors.white,
                  borderRadius: BorderRadius.circular(context.r(12)),
                  border: Border.all(
                    color: selected
                        ? const Color(0xff1663F7)
                        : const Color(0xffE6ECFF),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xff1663F7).withValues(alpha: 0.25),
                            blurRadius: context.w(8),
                            offset: Offset(0, context.h(3)),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date),
                      style: TextStyle(
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xff9AA2BF),
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      DateFormat('d MMM').format(date),
                      style: TextStyle(
                        fontSize: context.fs(13),
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : const Color(0xff3D3F4A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Route summary
  // ---------------------------------------------------------------------------
  Widget _buildRouteSummary(List<FlightEntity> flights) {
    final sampleFlight = flights.isNotEmpty ? flights.first : null;
    final duration = sampleFlight?.duration != null
        ? _formatDuration(int.tryParse(sampleFlight!.duration!))
        : '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(15),
        context.h(16),
        context.w(15),
        context.h(18),
      ),
      decoration: const BoxDecoration(color: Color(0xffF8FAFF)),
      child: Column(
        children: [
          SizedBox(
            height: context.h(98),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RouteArcPainter(color: AppColors.primary),
                  ),
                ),
                Positioned(
                  top: context.h(36),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(12),
                      vertical: context.h(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.r(14)),
                      border: Border.all(color: const Color(0xffE6ECFF)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xff4B74FF).withValues(alpha: 0.08),
                          blurRadius: context.w(14),
                          offset: Offset(0, context.h(4)),
                        ),
                      ],
                    ),
                    child: Text(
                      duration.isEmpty ? widget.travelClass : duration,
                      style: TextStyle(
                        color: const Color(0xff3F4350),
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _routeCityBlock(
                        code: widget.fromCode,
                        city: widget.from,
                        alignRight: false),
                    _routeCityBlock(
                        code: widget.toCode,
                        city: widget.to,
                        alignRight: true),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(8)),
          Text(
            "${widget.travellers} Traveller${widget.travellers > 1 ? 's' : ''} • ${widget.travelClass}",
            style: TextStyle(
              color: const Color(0xff9AA2BF),
              fontSize: context.fs(12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCityBlock({
    required String code,
    required String city,
    required bool alignRight,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          code,
          style: TextStyle(
            color: const Color(0xff3D3F4A),
            fontSize: context.fs(28),
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        SizedBox(height: context.h(5)),
        Text(
          city,
          style: TextStyle(
            color: const Color(0xffA0A6C2),
            fontSize: context.fs(13),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sort bar
  // ---------------------------------------------------------------------------
  Widget _buildSortBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(8),
        context.w(14),
        context.h(8),
      ),
      child: Row(
        children: [
          // Filter button
          GestureDetector(
            onTap: _openFilterDrawer,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(7),
              ),
              decoration: BoxDecoration(
                color: _hasActiveFilters()
                    ? const Color(0xff1663F7)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(context.r(20)),
                border: Border.all(
                  color: _hasActiveFilters()
                      ? const Color(0xff1663F7)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: context.w(14),
                    color: _hasActiveFilters() ? Colors.white : Colors.grey.shade700,
                  ),
                  SizedBox(width: context.w(5)),
                  Text(
                    "Filter",
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w600,
                      color: _hasActiveFilters()
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: context.w(8)),
          // Sort chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sortOptions.map((opt) {
                  final selected = _selectedSort == opt;
                  return Padding(
                    padding: EdgeInsets.only(right: context.w(6)),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSort = opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(12),
                          vertical: context.h(7),
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xff1663F7)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(context.r(20)),
                          border: Border.all(
                            color: selected
                                ? const Color(0xff1663F7)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: context.fs(12),
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedDepartureTimes.isNotEmpty ||
        _selectedArrivalTimes.isNotEmpty ||
        _filterRefundable ||
        _filterNonRefundable ||
        (_selectedAirlines.isNotEmpty &&
            _selectedAirlines.length <
                _buildAirlineCounts(_allFlights).length) ||
        (_allFlights.isNotEmpty &&
            (_priceRange.start > _minPrice ||
                _priceRange.end < _maxPrice));
  }

  // ---------------------------------------------------------------------------
  // Flight list (grouped)
  // ---------------------------------------------------------------------------
  Widget _buildFlightList(
    List<_FlightGroup> groups,
    int filteredCount,
    int totalCount,
  ) {
    if (groups.isEmpty) {
      return _buildNoResultsState();
    }
    return Container(
      color: const Color(0xffF3F6FF),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildRouteSummary(_applyFilters(_allFlights)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(14),
                context.h(10),
                context.w(14),
                context.h(6),
              ),
              child: _buildResultsHeader(filteredCount, totalCount),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              context.w(10),
              0,
              context.w(10),
              context.h(18),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGroupCard(groups[index]),
                childCount: groups.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Inline flight-card offers (MMT style)
  // ---------------------------------------------------------------------------
  static const List<_FlightOffer> _offers = [
    _FlightOffer(
      title: 'Free seat with Visa Signature cards',
      code: 'VISASEAT',
      icon: Icons.airline_seat_recline_extra_rounded,
    ),
    _FlightOffer(
      title: 'Get ₹1,500 OFF with HDFC Credit Cards',
      code: 'WNHDFC',
      icon: Icons.local_offer_rounded,
    ),
    _FlightOffer(
      title: 'Up to ₹2,000 OFF on your first booking',
      code: 'WELCOME2K',
      icon: Icons.card_giftcard_rounded,
    ),
    _FlightOffer(
      title: '10% Cashback via Wander Wallet',
      code: 'WNWALLET',
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  /// Deterministically pick an offer for a flight so each card consistently
  /// shows the same one across rebuilds.
  _FlightOffer _offerFor(FlightEntity flight) {
    final seed = (flight.resultIndex ?? flight.flightNumber ?? flight.airlineCode ?? '')
        .codeUnits
        .fold<int>(0, (s, u) => s + u);
    return _offers[seed % _offers.length];
  }

  /// MMT-style inline offer row shown at the bottom of a flight card.
  Widget _buildCardOffer(FlightEntity flight) {
    final offer = _offerFor(flight);
    const Color offerColor = Color(0xff1A7F5A); // MMT-like green
    return Container(
      width: double.infinity,
      child: Row(
        children: [
          Icon(offer.icon, size: context.w(14), color: offerColor),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Text(
              offer.title,
              style: TextStyle(
                color: offerColor,
                fontSize: context.fs(11),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: context.w(6)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(6),
              vertical: context.h(1),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: offerColor.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(context.r(4)),
            ),
            child: Text(
              offer.code,
              style: TextStyle(
                color: offerColor,
                fontSize: context.fs(9),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int showing, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$showing of $total Flights",
          style: TextStyle(
            fontSize: context.fs(12),
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        if (_hasActiveFilters())
          GestureDetector(
            onTap: () => setState(() {
              _selectedDepartureTimes.clear();
              _selectedArrivalTimes.clear();
              _filterRefundable = false;
              _filterNonRefundable = false;
              _selectedAirlines =
                  _allFlights.map((f) => f.airlineName ?? 'Unknown').toSet();
              _priceRange = RangeValues(_minPrice, _maxPrice);
            }),
            child: Text(
              "Clear Filters",
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: const Color(0xff1663F7),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Group card
  // ---------------------------------------------------------------------------
  Widget _buildGroupCard(_FlightGroup group) {
    final isExpanded = _expandedGroups.contains(group.key);
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary card
          _buildFlightCardInner(
            group.primary,
            extraCount: group.extras.length,
            isExpanded: isExpanded,
            onMoreTap: group.extras.isEmpty
                ? null
                : () => setState(() {
                      if (isExpanded) {
                        _expandedGroups.remove(group.key);
                      } else {
                        _expandedGroups.add(group.key);
                      }
                    }),
          ),
          // Expanded extra cards
          if (isExpanded)
            ...group.extras
                .map((f) => Padding(
                      padding: EdgeInsets.only(top: context.h(6)),
                      child: _buildExtraCard(f),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildFlightCardInner(
    FlightEntity flight, {
    int extraCount = 0,
    bool isExpanded = false,
    VoidCallback? onMoreTap,
  }) {
    final bool isRoundTrip = flight.isRoundTrip;
    final Color accentColor =
        isRoundTrip ? const Color(0xff3B82F6) : AppColors.primary;
    final departure = _formatTime(flight.departureTime);
    final arrival = _formatTime(flight.arrivalTime);
    final duration = _formatDuration(
        flight.duration != null ? int.tryParse(flight.duration!) : null);
    final airlineCode = (flight.airlineCode?.isNotEmpty ?? false)
        ? flight.airlineCode!.toUpperCase()
        : (flight.airlineName?.isNotEmpty ?? false)
            ? flight.airlineName!.substring(0, 1).toUpperCase()
            : 'FL';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: const Color(0xffE9EDF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2B3A67).withValues(alpha: 0.05),
            blurRadius: context.w(10),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFlightDetails(flight),
          borderRadius: BorderRadius.circular(context.r(14)),
          child: Padding(
            padding: EdgeInsets.all(context.w(12)),
            child: Column(
              children: [
                // Header row: logo + airline name/flight no + price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _airlineLogo(flight, context.w(34)),
                    SizedBox(width: context.w(8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            flight.airlineName ?? 'Airline',
                            style: TextStyle(
                              color: const Color(0xff3D3F4A),
                              fontSize: context.fs(13),
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: context.h(1)),
                          Text(
                            '$airlineCode ${flight.flightNumber ?? ''}'.trim(),
                            style: TextStyle(
                              color: const Color(0xffA0A6C2),
                              fontSize: context.fs(10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Text(
                      _convertFlightPrice(
                        (flight.totalFare ?? 0).toDouble(),
                        flight.currency,
                      ),
                      style: TextStyle(
                        color: const Color(0xff1663F7),
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                if (!isRoundTrip)
                  // Compact one-way route row (MMT style)
                  Row(
                    children: [
                      _timeAirportBlock(
                        time: departure,
                        code: flight.origin ?? widget.fromCode,
                        alignRight: false,
                      ),
                      SizedBox(width: context.w(8)),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              duration,
                              style: TextStyle(
                                color: const Color(0xff9AA2BF),
                                fontSize: context.fs(10),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: context.h(4)),
                            _ticketFlightPath(accentColor),
                            if (_formatStops(flight.stops).isNotEmpty) ...[
                              SizedBox(height: context.h(4)),
                              Text(
                                _formatStops(flight.stops),
                                style: TextStyle(
                                  color: const Color(0xff9AA2BF),
                                  fontSize: context.fs(10),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: context.w(8)),
                      _timeAirportBlock(
                        time: arrival,
                        code: flight.destination ?? widget.toCode,
                        alignRight: true,
                      ),
                    ],
                  )
                else
                  // Round-trip — two labelled legs (Depart + Return)
                  _roundTripBody(flight, accentColor),
                // MMT-style inline offer
                SizedBox(height: context.h(10)),
                _buildCardOffer(flight),
                // "N more flights" badge
                if (extraCount > 0) ...[
                  SizedBox(height: context.h(10)),
                  GestureDetector(
                    onTap: onMoreTap,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(12),
                        vertical: context.h(7),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff1663F7).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(context.r(10)),
                        border: Border.all(
                          color: const Color(0xff1663F7).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: context.w(16),
                            color: const Color(0xff1663F7),
                          ),
                          SizedBox(width: context.w(5)),
                          Text(
                            isExpanded
                                ? 'Hide extra flights'
                                : '$extraCount more flight${extraCount > 1 ? 's' : ''} at this price',
                            style: TextStyle(
                              fontSize: context.fs(12),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1663F7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact card for extra flights in an expanded group
  Widget _buildExtraCard(FlightEntity flight) {
    final accentColor =
        flight.isRoundTrip ? const Color(0xff3B82F6) : const Color(0xff5F86FF);
    final dep = _formatTime(flight.departureTime);
    final arr = _formatTime(flight.arrivalTime);
    final dur = _formatDuration(
        flight.duration != null ? int.tryParse(flight.duration!) : null);
    final code = (flight.airlineCode?.isNotEmpty ?? false)
        ? flight.airlineCode!.toUpperCase()
        : 'FL';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(12)),
      child: InkWell(
        onTap: () => _showFlightDetails(flight),
        borderRadius: BorderRadius.circular(context.r(12)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: const Color(0xffE6ECFF)),
          ),
          child: Row(
            children: [
              _airlineLogo(flight, context.w(24)),
              SizedBox(width: context.w(8)),
              Text(
                '$code${flight.flightNumber ?? ''}',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff3D3F4A),
                ),
              ),
              SizedBox(width: context.w(12)),
              Text(
                dep,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff3D3F4A),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(8)),
                child: Icon(Icons.flight, size: context.w(14), color: accentColor),
              ),
              Text(
                arr,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff3D3F4A),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(3),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffF3F6FF),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Text(
                  dur,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff5F86FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared card sub-widgets
  // ---------------------------------------------------------------------------
  Widget _timeAirportBlock({
    required String time,
    required String code,
    required bool alignRight,
  }) {
    return SizedBox(
      width: context.w(76),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: TextStyle(
              color: const Color(0xff3D3F4A),
              fontSize: context.fs(18),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(3)),
          Text(
            code,
            style: TextStyle(
              color: const Color(0xffA0A6C2),
              fontSize: context.fs(11),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _ticketFlightPath(Color color) {
    return Row(
      children: [
        _pathDot(color),
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
            child: SizedBox(height: context.h(1)),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(6)),
          child: Icon(Icons.flight, color: color, size: context.w(22)),
        ),
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
            child: SizedBox(height: context.h(1)),
          ),
        ),
        _pathDot(color),
      ],
    );
  }

  Widget _pathDot(Color color) {
    return Container(
      width: context.w(9),
      height: context.w(9),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: context.w(8),
            spreadRadius: context.w(1),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider() {
    return CustomPaint(
      painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
      child: SizedBox(width: double.infinity, height: context.h(1)),
    );
  }

  Widget _ticketMetaChip({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xffA0A6C2),
            fontSize: context.fs(11),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.h(4)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(10),
            vertical: context.h(4),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: const Color(0xffE6ECFF)),
          ),
          child: Text(
            value.isEmpty ? '--' : value,
            style: TextStyle(
              color: const Color(0xff3D3F4A),
              fontSize: context.fs(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Round-trip card body: an outbound (Depart) leg and a Return leg,
  /// each rendered like a mini flight ticket. One-way cards never use this.
  Widget _roundTripBody(FlightEntity flight, Color accentColor) {
    final outDuration = _formatDuration(
        flight.duration != null ? int.tryParse(flight.duration!) : null);
    final retDuration = _formatDuration(flight.returnDuration != null
        ? int.tryParse(flight.returnDuration!)
        : null);

    return Column(
      children: [
        _legBlock(
          label: 'Depart',
          icon: Icons.flight_takeoff,
          originCode: flight.origin ?? widget.fromCode,
          destCode: flight.destination ?? widget.toCode,
          depTime: _formatTime(flight.departureTime),
          arrTime: _formatTime(flight.arrivalTime),
          date: _formatReadableFlightDate(flight.departureTime),
          duration: outDuration,
          stops: _formatStops(flight.stops),
          accentColor: accentColor,
        ),
        SizedBox(height: context.h(14)),
        _dashedDivider(),
        SizedBox(height: context.h(14)),
        _legBlock(
          label: 'Return',
          icon: Icons.flight_land,
          originCode:
              flight.returnOrigin ?? flight.destination ?? widget.toCode,
          destCode:
              flight.returnDestination ?? flight.origin ?? widget.fromCode,
          depTime: _formatTime(flight.returnDepartureTime),
          arrTime: _formatTime(flight.returnArrivalTime),
          date: _formatReadableFlightDate(flight.returnDepartureTime),
          duration: retDuration,
          stops: _formatStops(flight.returnStops),
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _legBlock({
    required String label,
    required IconData icon,
    required String originCode,
    required String destCode,
    required String depTime,
    required String arrTime,
    required String date,
    required String duration,
    required Color accentColor,
    String stops = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leg label with a divider line
        Row(
          children: [
            Icon(icon, size: context.w(14), color: accentColor),
            SizedBox(width: context.w(6)),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Container(height: 1, color: const Color(0xffEDF0F7)),
            ),
          ],
        ),
        SizedBox(height: context.h(14)),
        Row(
          children: [
            _timeAirportBlock(time: depTime, code: originCode, alignRight: false),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ticketFlightPath(accentColor),
                  if (stops.isNotEmpty) ...[
                    SizedBox(height: context.h(4)),
                    Text(
                      stops,
                      style: TextStyle(
                        color: const Color(0xff9AA2BF),
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.w(12)),
            _timeAirportBlock(time: arrTime, code: destCode, alignRight: true),
          ],
        ),
        SizedBox(height: context.h(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ticketMetaChip(label: 'Date:', value: date),
            _ticketMetaChip(label: 'Duration:', value: duration),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Detail popup
  // ---------------------------------------------------------------------------
  void _showFlightDetails(FlightEntity flight) {
    FlightDetailsPopup.show(
      context,
      airlineName: flight.airlineName ?? "Unknown",
      airlineCode: flight.airlineName ?? "--",
      flightNumber: flight.flightNumber ?? "--",
      fromCode: flight.origin ?? "--",
      toCode: flight.destination ?? "--",
      departureTime: _formatTime(flight.departureTime),
      arrivalTime: _formatTime(flight.arrivalTime),
      traceId: flight.traceId,
      resultIndex: flight.resultIndex,
      // resultIndex: 'OB1',
      duration: "${flight.duration ?? '--'} min",
      price: _convertFlightPrice(
        (flight.totalFare ?? 0).toDouble(),
        flight.currency,
      ),
      travellerCount: widget.travellers,
    );
  }

  // ---------------------------------------------------------------------------
  // Empty / error states
  // ---------------------------------------------------------------------------
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: context.iconXLarge, color: Colors.grey.shade400),
          SizedBox(height: context.gapLarge),
          Text(
            'No flights match your filters',
            style: TextStyle(
                fontSize: context.fs(18), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: context.gapSmall),
          TextButton(
            onPressed: () => setState(() {
              _selectedDepartureTimes.clear();
              _selectedArrivalTimes.clear();
              _filterRefundable = false;
              _filterNonRefundable = false;
              _selectedAirlines =
                  _allFlights.map((f) => f.airlineName ?? 'Unknown').toSet();
              _priceRange = RangeValues(_minPrice, _maxPrice);
            }),
            child: Text(
              'Clear all filters',
              style: TextStyle(
                  fontSize: context.fs(14), color: const Color(0xff1663F7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: context.horizontalPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: context.iconXLarge, color: Colors.red.shade400),
            SizedBox(height: context.gapLarge),
            Text('Failed to load flights',
                style: TextStyle(
                    fontSize: context.fs(20), fontWeight: FontWeight.w600)),
            SizedBox(height: context.gapSmall),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: context.fs(14), color: Colors.grey.shade600)),
            SizedBox(height: context.gapXLarge),
            ElevatedButton(
              onPressed: _triggerFlightSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                padding: EdgeInsets.symmetric(
                  horizontal: context.buttonWidth,
                  vertical: context.gapMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff,
              size: context.iconXLarge * 1.5, color: Colors.grey.shade400),
          SizedBox(height: context.gapLarge),
          Text('Search for flights',
              style: TextStyle(
                  fontSize: context.fs(20), fontWeight: FontWeight.w600)),
          SizedBox(height: context.gapSmall),
          Text('Enter your travel details to find the best flights',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: context.fs(14), color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _formatTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }

  /// MMT-style stops label, taken from the API response.
  /// 0 stops → "Non stop", otherwise "1 Stop" / "2 Stops".
  String _formatStops(int? stops) {
    if (stops == null) return '';
    if (stops <= 0) return 'Non stop';
    return '$stops Stop${stops > 1 ? 's' : ''}';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return '0';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _formatReadableFlightDate(String? isoTime) {
    final source = isoTime ?? widget.date?.toIso8601String();
    if (source == null || source.isEmpty) return _formatDate(widget.date);
    try {
      return DateFormat('MMMM d, yyyy').format(DateTime.parse(source));
    } catch (_) {
      return _formatDate(widget.date);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _convertFlightPrice(double amount, String? apiCurrency) {
    try {
      final prefs = sl<PreferencesManager>();
      final target = prefs.getPreferredCurrency() ?? 'INR';
      final from = apiCurrency ?? 'INR';
      if (from.toUpperCase() == target.toUpperCase()) {
        return _formatIndianNumber(amount.toInt());
      }
      final converted =
          CurrencyConverter.convert(amount: amount, fromCurrency: from, toCurrency: target);
      if (target.toUpperCase() == 'INR') {
        return _formatIndianNumber(converted.toInt());
      }
      return converted.toStringAsFixed(0);
    } catch (_) {
      return _formatIndianNumber(amount.toInt());
    }
  }

  String _formatIndianNumber(int num) {
    if (num < 1000) return num.toString();
    final str = num.toString();
    final last3 = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    var formatted = '';
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) formatted += ',';
      formatted += remaining[i];
    }
    return '$formatted,$last3';
  }

  Color _airlineColor(String code) {
    const colors = [
      Color(0xffC29200),
      Color(0xff25358D),
      Color(0xff7A003C),
      Color(0xff0F766E),
      Color(0xffB42318),
    ];
    final hash = code.codeUnits.fold<int>(0, (s, u) => s + u);
    return colors[hash % colors.length];
  }

  /// Airline logo fetched from the Kiwi CDN by IATA code, with a graceful
  /// fallback to a coloured initials tile when the logo is missing/offline.
  Widget _airlineLogo(FlightEntity flight, double size) {
    final code = (flight.airlineCode ?? '').trim().toUpperCase();
    final initials = code.isNotEmpty
        ? (code.length > 2 ? code.substring(0, 2) : code)
        : ((flight.airlineName?.isNotEmpty ?? false)
            ? flight.airlineName!.substring(0, 1).toUpperCase()
            : 'FL');

    Widget initialsTile() => Container(
          color: _airlineColor(initials),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: const Color(0xffE6ECFF)),
      ),
      child: code.isEmpty
          ? initialsTile()
          : Padding(
              padding: EdgeInsets.all(context.w(3)),
              child: CachedNetworkImage(
                imageUrl: 'https://images.kiwi.com/airlines/64/$code.png',
                fit: BoxFit.contain,
                placeholder: (_, __) => initialsTile(),
                errorWidget: (_, __, ___) => initialsTile(),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painters
// ---------------------------------------------------------------------------
class _RouteArcPainter extends CustomPainter {
  final Color color;
  _RouteArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final start = Offset(size.width * 0.24, size.height * 0.58);
    final end = Offset(size.width * 0.76, size.height * 0.58);
    final control = Offset(size.width * 0.5, size.height * 0.05);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
    _drawDot(canvas, start);
    _drawDot(canvas, end);

    final tangentAngle = math.atan2(end.dy - control.dy, end.dx - control.dx);
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.18);
    canvas.rotate(tangentAngle + math.pi / 16);
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.flight.codePoint),
        style: TextStyle(
          fontFamily: Icons.flight.fontFamily,
          package: Icons.flight.fontPackage,
          color: color,
          fontSize: 22,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    iconPainter.paint(
        canvas, Offset(-iconPainter.width / 2, -iconPainter.height / 2));
    canvas.restore();
  }

  void _drawDot(Canvas canvas, Offset offset) {
    canvas.drawCircle(offset, 5, Paint()..color = color);
    canvas.drawCircle(
        offset, 9, Paint()..color = color.withValues(alpha: 0.12));
  }

  @override
  bool shouldRepaint(covariant _RouteArcPainter old) => old.color != color;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, y), Offset(math.min(x + dashWidth, size.width), y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
