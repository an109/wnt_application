import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/newUIWidgets/flightCard.dart';
import 'package:wander_nova/newUIWidgets/sheetActionButtons.dart';
import '../../../../../injection_container.dart';
import '../../../../UI_helper/currency_converter.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/loadingScreen.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../domain/entities/flight_entity.dart';
import '../../domain/entities/fare_trip_type.dart';
// Legacy TBO search — replaced by the Akbar ExpressSearch/GetExpSearch tui flow below.
// import '../../domain/entities/flight_search_request_entity.dart';
// import '../bloc/flight_search_bloc.dart';
// import '../bloc/flight_search_event.dart';
// import '../bloc/flight_search_state.dart';
import 'package:wander_nova/views/AKFlight_tui/domain/entity/akflight_search_entity.dart';
import 'package:wander_nova/views/AKFlight_tui/domain/usecase/akflight_search_usecase.dart';
import 'package:wander_nova/views/AKFlights/domain/entity/AKFlights_entity.dart' as ak;
import 'package:wander_nova/views/AKFlights/presentation/bloc/AKFlights_bloc.dart';
import 'package:wander_nova/views/AKFlights/presentation/bloc/AKFlights_event.dart';
import 'package:wander_nova/views/AKFlights/presentation/bloc/AKFlights_state.dart';
import 'detail_popup.dart';
import 'filter_screen.dart';

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
  final String tui;

  /// Wire fareType ('ON'/'RT'/'RS'/'DM'/'IM'). Defaults to 'ON' so the one
  /// existing caller that doesn't pass it (trending_routes.dart's one-way
  /// promo entry point) keeps behaving exactly as before.
  final String fareType;

  /// Populated only for Multi City (IM/DM) searches — one entry per leg,
  /// in order. Null/empty for ON/RT/RS, which use from/to/date above.
  final List<MultiCityLegSummary>? multiCityLegs;

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
    required this.tui,
    this.returnDate,
    this.fareType = 'ON',
    this.multiCityLegs,
  });

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // late FlightSearchBloc _flightSearchBloc; // legacy TBO search
  late AkflightsBloc _akflightsBloc;
  late String _currentTui;
  // True while a fresh tui is being fetched for a newly picked date on the
  // date strip, before the AkflightsBloc has a new LoadAkflightsEvent to
  // report loading state for.
  bool _isRefetchingTui = false;

  // filter & sort state
  String _selectedSort = "Lowest Price";
  RangeValues _priceRange = const RangeValues(0, 50000);
  double _maxPrice = 50000;
  double _minPrice = 0;
  Set<String> _selectedAirlines = {};
  Set<String> _selectedDepartureTimes = {};
  Set<String> _selectedArrivalTimes = {};
  bool _filterRefundable = false;
  bool _filterNonRefundable = false;
  // Filter screen: stop buckets (0 = non-stop, 1 = 1 stop, 2 = 2+ stops) and
  // an optional total-duration cap in minutes. Empty / null = no filter.
  Set<int> _selectedStops = {};
  RangeValues? _durationRange;
  // One-way results screen only — toggled from its bottom action bar. Left
  // false everywhere else, so _applyFilters is a no-op for the multi-leg flow.
  bool _nonStopOnly = false;
  // While false, _selectedAirlines is kept in sync with every airline seen
  // so far so flights from airlines that only show up in a later poll
  // aren't silently filtered out. Set once the user actually picks airlines
  // from the filter drawer.
  bool _userCustomizedAirlineFilter = false;

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
    "Lowest Price",
    "Direct Flights First",
    "Earliest Departure",
    "Latest Departure",
    "Earliest Arrival",
    "Latest Arrival",
    "Shortest Duration",
  ];

  // ---------------------------------------------------------------------------
  // Multi-leg (RT/RS/IM/DM) selection state. Unused whenever fareType is
  // 'ON' — the plain one-way flat-list -> tap-card -> detail-popup flow
  // below is untouched in that case. All legs render as side-by-side,
  // independently scrollable columns at once (not a sequential wizard) —
  // `_legSelections[i]` is null until the user taps a card in column i.
  // ---------------------------------------------------------------------------
  late final FareTripType _fareTripType;
  late List<FlightLegSelection?> _legSelections;

  // Round trip / special return only (`hasReturnLeg`) — the Wego-style
  // two-step selector: 0 = pick the departing flight, 1 = pick the
  // returning flight. Multi-city keeps the side-by-side column layout and
  // never reads this. Advances when the user taps a departing card;
  // "Change" on step 1 sets it back to 0.
  int _rtStep = 0;

  int get _legCount {
    if (_fareTripType.hasReturnLeg) return 2;
    if (_fareTripType.isMulticity) return widget.multiCityLegs?.length ?? 1;
    return 1;
  }

  /// One-way and round trip / special return share the Figma chrome: the
  /// route-summary header, the floating Sort / Non Stop / Filter bar, and no
  /// bottom nav. Multi-city keeps the original logo AppBar + bottom nav.
  bool get _usesOneWayChrome =>
      _fareTripType == FareTripType.oneWay || _fareTripType.hasReturnLeg;

  @override
  void initState() {
    super.initState();
    _fareTripType = FareTripTypeWire.fromWireValue(widget.fareType);
    _legSelections = List<FlightLegSelection?>.filled(_legCount, null);
    _akflightsBloc = sl<AkflightsBloc>();
    _currentTui = widget.tui;
    _selectedDate = widget.date != null
        ? DateUtils.dateOnly(widget.date!)
        : DateUtils.dateOnly(DateTime.now());
    _returnDate = widget.returnDate;
    _triggerFlightSearch();
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _akflightsBloc.close();
    super.dispose();
  }

  void _triggerFlightSearch() {
    if (_isApiCalled) return;
    _isApiCalled = true;
    _akflightsBloc.add(LoadAkflightsEvent(tui: _currentTui));
  }

  /// Re-run the search for a newly picked date from the date strip.
  ///
  /// The tui from the original search only ever returns flights for the
  /// date it was created with, so a new date needs a fresh ExpressSearch
  /// call (a new tui) before GetExpSearch can be polled for that date.
  void _onDateSelected(DateTime date) async {
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
      _userCustomizedAirlineFilter = false;
      _expandedGroups.clear();
      _isRefetchingTui = true;
    });

    final result = await sl<AkFlightSearchUseCase>().call(_buildTuiSearchRequest());

    if (!mounted) return;

    if (result is DataSuccess<AkFlightSearchEntity> && result.data != null) {
      _currentTui = result.data!.tui;
      _akflightsBloc.add(LoadAkflightsEvent(tui: _currentTui));
    } else {
      final message =
          result.error?.message ?? 'Failed to search flights for the selected date';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    if (mounted) setState(() => _isRefetchingTui = false);
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

  /// Builds the Akbar ExpressSearch request for the currently selected date.
  FlightSearchRequestEntity _buildTuiSearchRequest() {
    return FlightSearchRequestEntity(
      adults: widget.adults,
      children: widget.children,
      infants: widget.infants,
      cabin: _cabinCode(widget.travelClass),
      fareType: widget.fareType,
      trips: [
        TripEntity(
          from: widget.fromCode,
          to: widget.toCode,
          onwardDate: DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now()),
          returnDate: widget.isRoundTrip && _returnDate != null
              ? DateFormat('yyyy-MM-dd').format(_returnDate!)
              : null,
        ),
      ],
    );
  }

  String _cabinCode(String travelClass) {
    switch (travelClass) {
      case 'Premium Economy':
        return 'PE';
      case 'Business':
        return 'B';
      case 'First':
        return 'F';
      default:
        return 'E';
    }
  }

  /// Raw (pre-cheapest-per-flight) [FlightEntity] list for a single trip's
  /// Journey entries, plus the sibling-fare index used by the "Choose Your
  /// Fare" picker. Factored out of [_mapAkflightsToFlightEntities] so the
  /// multi-leg selector ([_mapAkflightsToLegLists]) can apply the exact same
  /// per-flight mapping to each leg independently, instead of pooling every
  /// leg's journeys into one list the way the one-way flow does.
  ({List<FlightEntity> flights, Map<String, Map<String, FareFamilyIndexEntity>> siblings})
      _rawFlightsForTrip(ak.TripEntity trip) {
    final flights = <FlightEntity>[];
    // Built alongside `flights` (not derived from FlightEntity afterwards)
    // because `flight.refundable` — needed for the fare-family picker's
    // "Refundable"/"Non-refundable" badge — only exists on the raw
    // AkflightsModel; FlightEntity doesn't carry it.
    final siblingsByKey = <String, Map<String, FareFamilyIndexEntity>>{};

    for (final flight in trip.journey) {
      // Every code field the API sends for a flight — Provider (an internal
      // fare-source label like "SB"/"S6E"), MAC (meant to be the clean IATA
      // code but has been seen as "CSG"/"ESG" instead of plain "SG"), even
      // FlightNo itself (e.g. "ESG 476") — has turned out unreliable for at
      // least some results, and any of those feeding the wrong value into
      // the Kiwi logo CDN lookup 404s, silently falling back to the
      // initials tile. The airline *name* the API sends is comparatively
      // stable, so look it up in a small table of known carriers first —
      // any flight named "SpiceJet" always gets SpiceJet's real code "SG",
      // regardless of what Provider/MAC/FlightNo happen to say — and only
      // fall back to parsing a code out of those fields for carriers not in
      // the table.
      final marketingName = _marketingSegment(flight.airlineName, fallback: '');
      final realAirlineCode = _knownAirlineCode(marketingName) ??
          _carrierCodeFromFlightNo(flight.flightNo) ??
          (flight.marketingAirlineCode.isNotEmpty
              ? flight.marketingAirlineCode
              : flight.provider);
      flights.add(FlightEntity(
        resultIndex: flight.index,
        airlineCode: realAirlineCode,
        airlineName: marketingName.isNotEmpty ? marketingName : realAirlineCode,
        flightNumber: flight.flightNo,
        origin: flight.origin,
        originName: _lastSegment(flight.originName),
        destination: flight.destination,
        destinationName: _lastSegment(flight.destinationName),
        departureTime: flight.departureTime,
        arrivalTime: flight.arrivalTime,
        totalFare: flight.netFare,
        stops: flight.stops,
        duration: _durationToMinutes(flight.duration),
        cabinClass: flight.cabin,
      ));

      final key = '${realAirlineCode}_${flight.flightNo}_${flight.departureTime}';
      siblingsByKey.putIfAbsent(key, () => {})[flight.index] = FareFamilyIndexEntity(
        index: flight.index,
        amount: flight.netFare,
        refundable: flight.refundable.toUpperCase() == 'Y',
      );
    }
    return (flights: flights, siblings: siblingsByKey);
  }

  /// Maps the Akbar GetExpSearch response into the [FlightEntity] shape the
  /// existing UI renders. Each entry in a trip's Journey list is already a
  /// directly bookable flight option (fare-class variant) with its own
  /// route/airline/duration, so this is a flat 1:1 mapping — then collapsed
  /// down to one card per physical flight. Used for the plain one-way ('ON')
  /// flow, where `data.trips` only ever has one entry.
  List<FlightEntity> _mapAkflightsToFlightEntities(ak.AkflightsSearchEntity data) {
    final flights = <FlightEntity>[];
    final siblingsByKey = <String, Map<String, FareFamilyIndexEntity>>{};
    for (final trip in data.trips) {
      final raw = _rawFlightsForTrip(trip);
      flights.addAll(raw.flights);
      raw.siblings.forEach((key, value) {
        siblingsByKey.putIfAbsent(key, () => {}).addAll(value);
      });
    }
    return _cheapestPerFlight(flights, siblingsByKey);
  }

  /// Same mapping as [_mapAkflightsToFlightEntities], but keeps each trip's
  /// results in its own list instead of pooling them — used by the RT/RS/
  /// IM/DM results screen, which needs the user to pick one flight per leg
  /// rather than one flight overall.
  List<List<FlightEntity>> _mapAkflightsToLegLists(ak.AkflightsSearchEntity data) {
    return data.trips.map((trip) {
      final raw = _rawFlightsForTrip(trip);
      return _cheapestPerFlight(raw.flights, raw.siblings);
    }).toList();
  }

  List<FlightEntity> _cheapestPerFlight(
    List<FlightEntity> flights,
    Map<String, Map<String, FareFamilyIndexEntity>> siblingsByKey,
  ) {
    final cheapest = <String, FlightEntity>{};

    for (final f in flights) {
      final key = '${f.airlineCode ?? ''}_${f.flightNumber ?? ''}_${f.departureTime ?? ''}';
      final existing = cheapest[key];
      if (existing == null ||
          (f.totalFare ?? double.infinity) < (existing.totalFare ?? double.infinity)) {
        cheapest[key] = f;
      }
    }

    return cheapest.entries.map((entry) {
      final options = siblingsByKey[entry.key]?.values.toList();
      // Only worth attaching when there's genuinely more than one fare —
      // avoids showing a picker of one for the common single-fare flight.
      if (options == null || options.length <= 1) return entry.value;
      return entry.value.copyWith(fareFamilyOptions: options);
    }).toList();
  }

  /// AirlineName comes as "ValidatingName|MarketingName|OperatingName"
  /// (mirroring the VAC|MAC|OAC codes) — e.g. "IndiGo|IndiGo|IndiGo", or a
  /// mismatched triple for a codeshare. Picks the marketing-carrier segment
  /// (index 1) so the displayed name always matches the displayed code
  /// (which is also the marketing carrier's), falling back to whichever
  /// segment is non-empty.
  String _marketingSegment(String value, {required String fallback}) {
    final parts = value.split('|').map((p) => p.trim()).toList();
    if (parts.length > 1 && parts[1].isNotEmpty) return parts[1];
    final firstNonEmpty = parts.firstWhere((p) => p.isNotEmpty, orElse: () => '');
    return firstNonEmpty.isNotEmpty ? firstNonEmpty : fallback;
  }

  /// Recovers the operating/marketing carrier's real 2-char IATA code from a
  /// raw flight number, e.g. "6E-2134", "6E 2134", "6E2134" -> "6E". Only a
  /// secondary fallback now (see [_rawFlightsForTrip] — [_knownAirlineCode]
  /// is tried first), for carriers not in that table. Requires at least one
  /// letter in the 2-char prefix so a plain numeric flight number (no
  /// prefix) is correctly rejected instead of matching garbage.
  String? _carrierCodeFromFlightNo(String flightNo) {
    final match = RegExp(r'^([A-Za-z][A-Za-z0-9]|[0-9][A-Za-z])[\s-]?\d')
        .firstMatch(flightNo.trim());
    return match?.group(1)?.toUpperCase();
  }

  /// Airline name -> real IATA code for the carriers this app sees most —
  /// checked before any code field the API itself sends, since those have
  /// proven unreliable (see [_rawFlightsForTrip]) while the name is stable.
  /// Matched case-insensitively; unrecognised names return null and fall
  /// through to the flight-number/MAC/provider chain as before.
  static const Map<String, String> _knownAirlineCodesByName = {
    'spicejet': 'SG',
    'indigo': '6E',
    'air india': 'AI',
    'air india express': 'IX',
    'vistara': 'UK',
    'akasa air': 'QP',
    'akasa': 'QP',
    'airasia india': 'I5',
    'go first': 'G8',
    'goair': 'G8',
    'alliance air': '9I',
    'star air': 'S5',
    'trujet': '2T',
    'jet airways': '9W',
    'emirates': 'EK',
    'qatar airways': 'QR',
    'etihad airways': 'EY',
    'etihad': 'EY',
    'oman air': 'WY',
    'srilankan airlines': 'UL',
    'srilankan': 'UL',
    'flydubai': 'FZ',
    'air arabia': 'G9',
    'thai airways': 'TG',
    'singapore airlines': 'SQ',
    'malaysia airlines': 'MH',
    'cathay pacific': 'CX',
    'british airways': 'BA',
    'lufthansa': 'LH',
    'air france': 'AF',
    'klm': 'KL',
    'klm royal dutch airlines': 'KL',
    'turkish airlines': 'TK',
    'saudia': 'SV',
    'gulf air': 'GF',
    'kuwait airways': 'KU',
    'nepal airlines': 'RA',
    'bhutan airlines': 'B3',
    'druk air': 'KB',
  };

  String? _knownAirlineCode(String name) {
    return _knownAirlineCodesByName[name.trim().toLowerCase()];
  }

  /// Strips a (possibly wrong — see [_rawFlightsForTrip]) airline-code
  /// prefix baked into the raw FlightNo, keeping just the trailing digits
  /// (with an optional trailing letter suffix, e.g. "101A"). Falls back to
  /// the untouched raw string if no trailing number is found.
  String _bareFlightNo(String? flightNo) {
    final raw = (flightNo ?? '').trim();
    if (raw.isEmpty) return '';
    final match = RegExp(r'(\d+[A-Za-z]?)\s*$').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  /// Flight number as it should be displayed: the verified airline code
  /// (defaults to [FlightEntity.airlineCode], which [_rawFlightsForTrip]
  /// already resolves correctly) plus the bare digits from the raw FlightNo,
  /// so a mismatched prefix baked into the raw value (e.g. "ESG 476" for a
  /// flight whose real code is "SG") never reaches the UI stacked on top of
  /// the already-correct code.
  String _displayFlightNo(FlightEntity flight, {String? codeOverride}) {
    final code = (codeOverride ?? flight.airlineCode ?? '').trim().toUpperCase();
    final number = _bareFlightNo(flight.flightNumber);
    return [code, number].where((s) => s.isNotEmpty).join(' ');
  }

  /// "Indira Gandhi International |New Delhi" -> "New Delhi"
  String _lastSegment(String value) {
    final parts = value.split('|');
    final last = parts.last.trim();
    return last.isNotEmpty ? last : value.trim();
  }

  /// "01h 25m " -> "85" (minutes), matching what `_formatDuration` expects.
  String? _durationToMinutes(String duration) {
    final hours = int.tryParse(RegExp(r'(\d+)h').firstMatch(duration)?.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(RegExp(r'(\d+)m').firstMatch(duration)?.group(1) ?? '') ?? 0;
    final total = hours * 60 + minutes;
    return total > 0 ? total.toString() : null;
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

  /// Airline name -> IATA code, so the filter drawer's "Airlines" section can
  /// show the same real logo as the results list instead of a plain
  /// initials circle. Keyed by name (like the maps above) since that's what
  /// the drawer groups by; first flight to claim a name wins its code.
  Map<String, String> _buildAirlineCodes(List<FlightEntity> flights) {
    final map = <String, String>{};
    for (final f in flights) {
      final name = f.airlineName ?? 'Unknown';
      final code = f.airlineCode ?? '';
      if (code.isNotEmpty && !map.containsKey(name)) map[name] = code;
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

    // non-stop only (one-way bottom bar)
    if (_nonStopOnly) {
      result = result.where((f) => (f.stops ?? 0) <= 0).toList();
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

    // stop buckets (filter screen)
    if (_selectedStops.isNotEmpty) {
      result = result.where((f) {
        final s = f.stops ?? 0;
        final bucket = s <= 0 ? 0 : (s == 1 ? 1 : 2);
        return _selectedStops.contains(bucket);
      }).toList();
    }

    // total-duration cap (filter screen)
    final dr = _durationRange;
    if (dr != null) {
      result = result.where((f) {
        final d = _flightDurationMinutes(f);
        return d == 0 || (d >= dr.start && d <= dr.end);
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
    final airlineNames = flights.map((f) => f.airlineName ?? 'Unknown').toSet();

    // Nothing changed — skip the rebuild. Airline count is checked too since
    // a later poll can add flights from a new airline within the same price
    // range.
    final nothingChanged = newMax == _maxPrice &&
        newMin == _minPrice &&
        (_userCustomizedAirlineFilter ||
            _selectedAirlines.length == airlineNames.length);
    if (nothingChanged) return;

    // Defer setState to after the current build frame to avoid calling
    // setState() during a build, which triggers the assertion error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _maxPrice = newMax;
        _minPrice = newMin;
        _priceRange = RangeValues(newMin, newMax);
        // Keep "all airlines" selected by default as new ones stream in
        // from later polls, unless the user has picked specific airlines.
        if (!_userCustomizedAirlineFilter) {
          _selectedAirlines = airlineNames;
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Open the filter screen with current state
  // ---------------------------------------------------------------------------
  void _openFilterDrawer() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _buildFilterScreen()),
    );
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
      _selectedStops = result.selectedStops;
      _durationRange = result.durationRange;
      _userCustomizedAirlineFilter = true;
    });
  }

  /// stop bucket -> cheapest fare seen for it, in the API currency.
  Map<int, double> _buildStopMinPrices(List<FlightEntity> flights) {
    final map = <int, double>{};
    for (final f in flights) {
      final s = f.stops ?? 0;
      final bucket = s <= 0 ? 0 : (s == 1 ? 1 : 2);
      final price = (f.totalFare ?? 0).toDouble();
      if (!map.containsKey(bucket) || price < map[bucket]!) {
        map[bucket] = price;
      }
    }
    return map;
  }

  int _flightDurationMinutes(FlightEntity f) =>
      int.tryParse(f.duration ?? '') ?? 0;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return BlocProvider<AkflightsBloc>(
      create: (_) => _akflightsBloc,
      child: Scaffold(
        key: _scaffoldKey,
        // One-way and round trip keep the Figma route-summary header;
        // multi-city keeps the original Wander Nova logo bar, untouched.
        appBar: _usesOneWayChrome
            ? _buildOneWayHeader(context)
            : AppBar(
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
        backgroundColor: AppColors.white,
        body: BlocBuilder<AkflightsBloc, AkflightsState>(
          builder: (context, state) {
            final loadingScreen = ProfessionalLoadingScreen(
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

            if (_isRefetchingTui || state is AkflightsLoading) {
              return loadingScreen;
            }
            if (state is AkflightsFailed) {
              return _buildErrorState(
                  state.error.message ?? 'Failed to load flights');
            }
            if (state is AkflightsSuccess) {
              // Render as soon as a poll has any flights, even mid-search —
              // don't wait for isCompleted. Only fall back to the loading
              // screen if this poll genuinely has nothing yet.
              if (_fareTripType.isMultiLeg) {
                final legLists = _mapAkflightsToLegLists(state.akflightsData);
                final anyFlights = legLists.any((l) => l.isNotEmpty);
                if (!anyFlights && !state.isCompleted) return loadingScreen;
                _updateMaxPrice(legLists.expand((l) => l).toList());
                _autoSelectFirstFlights(legLists);
                return _buildMultiLegContent(legLists, isCompleted: state.isCompleted);
              }
              final flights = _mapAkflightsToFlightEntities(state.akflightsData);
              if (flights.isEmpty && !state.isCompleted) {
                return loadingScreen;
              }
              _updateMaxPrice(flights);
              return _buildMainContent(flights, isCompleted: state.isCompleted);
            }
            return _buildEmptyState();
          },
        ),
        // One-way and round trip use the Figma floating Sort / Non Stop /
        // Filter bar instead of the app bottom nav; multi-city keeps it.
        bottomNavigationBar: _usesOneWayChrome
            ? null
            : const CustomBottomNav(currentIndex: 0),
      ),
    );
  }

  Widget _buildFilterScreen() {
    // Derive the API currency from any flight in the cached list.
    // This is the same currency that totalFare values (and _priceRange) are stored in.
    final apiCurrency = _allFlights.isNotEmpty
        ? (_allFlights.first.currency ?? 'INR')
        : 'INR';

    // Duration bounds from the cached results (minutes).
    final durs = _allFlights
        .map(_flightDurationMinutes)
        .where((d) => d > 0)
        .toList();
    final minDur = durs.isEmpty ? 0.0 : durs.reduce(math.min).toDouble();
    final maxDur = durs.isEmpty ? 1440.0 : durs.reduce(math.max).toDouble();
    final maxStops = _allFlights.fold<int>(
        0, (m, f) => (f.stops ?? 0) > m ? (f.stops ?? 0) : m);

    return FlightFilterScreen(
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
      airlineCodes: _buildAirlineCodes(_allFlights),
      onApply: _onFilterApply,
      apiCurrency: apiCurrency,
      originCityName: widget.from,
      stopMinPrices: _buildStopMinPrices(_allFlights),
      maxStopsAvailable: maxStops,
      currentSelectedStops: _selectedStops,
      minDuration: minDur,
      maxDuration: maxDur,
      currentDurationRange: _durationRange ?? RangeValues(minDur, maxDur),
    );
  }

  Widget _buildMainContent(List<FlightEntity> flights, {required bool isCompleted}) {
    final filtered = _applyFilters(flights);
    final groups = _groupFlights(filtered);
    // One-way (Figma): date strip + results, with a floating Sort / Non Stop /
    // Filter bar at the bottom instead of the top sort chips.
    return Stack(
      children: [

        Column(
          children: [
            SizedBox(height: context.h(10)),
            _buildDateStrip(),
            SizedBox(height: context.h(10)),
            Expanded(
              child: _buildFlightList(
                groups,
                filtered.length,
                flights.length,
                isCompleted: isCompleted,
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildOneWayActionBar(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // One-way route-summary header (Figma "Search Flight own way")
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildOneWayHeader(BuildContext context) {
    final travellers = widget.adults + widget.children + widget.infants;
    final dateLabel = _selectedDate != null
        ? DateFormat('d MMM').format(_selectedDate!)
        : _formatDate(widget.date);
    final meta = '$dateLabel  |  $travellers '
        'Traveller${travellers == 1 ? '' : 's'}  |  ${widget.travelClass}';

    return PreferredSize(
      preferredSize: Size.fromHeight(context.h(78)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(16),
            context.h(8),
            context.w(16),
            context.h(6),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(10),
            ),
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF).withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(color: const Color(0xFFCCCCCC)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.arrow_back_rounded,
                      size: context.w(22), color: AppColors.subhead),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.from} to ${widget.to}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(8),
                          fontWeight: FontWeight.w500,
                          color: AppColors.subhead,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(8)),
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                    child: Image.asset(
                      'assets/NewIcons/edit.png',
                      width: context.w(15.83),
                      height: context.h(15.83),
                      color: AppColors.subhead
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // One-way bottom action bar: Sort | Non Stop | Filter
  // ---------------------------------------------------------------------------
  Widget _buildOneWayActionBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(6),
          context.w(16),
          context.h(10),
        ),
        child: Row(
          children: [
            // ==================================================
            // EXISTING SORT | NON STOP | FILTER BAR
            // ==================================================
            Expanded(
              child: Container(
                height: context.h(44.8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(context.r(30)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff2B3A67).withValues(alpha: 0.12),
                      blurRadius: context.w(15),
                      offset: Offset(0, context.h(4)),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _actionBarButton(
                        iconPath: 'assets/NewIcons/sort.png',
                        label: 'Sort',
                        onTap: _openSortSheet,
                      ),
                    ),
                    _actionBarDivider(),
                    Expanded(
                      child: _actionBarButton(
                        iconPath: 'assets/NewIcons/nonStop.png',
                        label: 'Non Stop',
                        active: _nonStopOnly,
                        onTap: () => setState(() => _nonStopOnly = !_nonStopOnly),
                      ),
                    ),
                    _actionBarDivider(),
                    Expanded(
                      child: _actionBarButton(
                        iconPath: 'assets/NewIcons/filter.png',
                        label: 'Filter',
                        active: _hasActiveFilters(),
                        onTap: _openFilterDrawer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // SPACING BETWEEN BAR AND AI BUTTON
            // ==================================================
            SizedBox(width: context.w(12)),

            // ==================================================
            // FLOATING AI BUTTON
            // ==================================================
            GestureDetector(
              onTap: () {
                debugPrint("AI button tapped in FlightScreen");
                // Add your AI functionality here
              },
              child: Container(
                width: context.w(48),
                height: context.h(48),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ==================================================
                    // COLORFUL AI FRAME
                    // ==================================================
                    ClipOval(
                      child: Image.asset(
                        'assets/Newgif/ai_frame.png',
                        width: context.w(60),
                        height: context.h(60),
                        fit: BoxFit.cover,
                      ),
                    ),
                    // ==================================================
                    // AI GIF
                    // ==================================================
                    ClipOval(
                      child: Image.asset(
                        'assets/Newgif/home_ai.gif',
                        width: context.w(62),
                        height: context.h(62),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBarDivider() {
    return Container(
      width: 1,
      height: context.h(20),
      color: const Color(0xffE6ECFF),
    );
  }

  Widget _actionBarButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final color =
        active ? AppColors.AppBlue : AppColors.black;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: context.w(16),
            height: context.w(16),
            color: color,
          ),
          SizedBox(width: context.w(6)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _openSortSheet() {
    // Pending selection — the visible list updates as the user taps, but
    // `_selectedSort` (and therefore the actual sort) only changes on DONE,
    // exactly as in the Figma. RESET reverts to the default option.
    String pendingSort = _selectedSort;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(
                        top: context.h(10),
                        bottom: context.h(4),
                      ),
                      width: context.w(100),
                      height: context.h(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D1D6),
                        borderRadius: BorderRadius.circular(context.r(24)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(16),
                      context.h(14),
                      context.w(20),
                      context.h(4),
                    ),
                    child: Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: context.fs(20),
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _sortOptions.map((opt) {
                          final selected = pendingSort == opt;
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: context.w(16),
                              vertical: context.h(1),
                            ),
                            dense: true, // Makes the ListTile more compact
                            visualDensity: VisualDensity.compact, // Reduces spacing even more
                            title: Text(
                              opt,
                              style: TextStyle(
                                fontSize: context.fs(15),
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                              ),
                            ),
                            trailing: _sortRadio(selected),
                            onTap: () =>
                                setSheetState(() => pendingSort = opt),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(3)),
                  SheetActionButtons(
                    onSecondary: () => setSheetState(
                      () => pendingSort = _sortOptions.first,
                    ),
                    onPrimary: () {
                      setState(() => _selectedSort = pendingSort);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortRadio(bool selected) {
    return SizedBox(
      width: context.w(16),
      height: context.w(16),
      child: Center(
        child: Container(
          width: context.w(16),
          height: context.w(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.AppBlue : const Color(0xffCCCCCC),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: selected
              ? Center(
                  child: Container(
                    width: context.w(6),
                    height: context.w(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.AppBlue,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RT/RS/IM/DM results — one column per leg, all visible and independently
  // scrollable at once (side by side), so the user can compare onward and
  // return options together instead of one after another. A Continue bar
  // appears once every column has a pick, opening the combined detail popup.
  // ---------------------------------------------------------------------------
  String _legLabel(int index) {
    if (_fareTripType.hasReturnLeg) {
      return index == 0 ? 'Onward' : 'Return';
    }
    final legs = widget.multiCityLegs;
    if (legs != null && index < legs.length) {
      return '${legs[index].fromCode} → ${legs[index].toCode}';
    }
    return 'Flight ${index + 1}';
  }

  Widget _buildMultiLegContent(List<List<FlightEntity>> legLists, {required bool isCompleted}) {
    // Round trip / special return use the Wego-style stepped selector.
    // Multi-city keeps the original side-by-side columns below, untouched.
    if (_fareTripType.hasReturnLeg) {
      return _buildRoundTripStepped(legLists, isCompleted: isCompleted);
    }
    return Column(
      children: [
        _buildSortBar(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < legLists.length; i++) ...[
                if (i > 0) Container(width: 1, color: const Color(0xffE6ECFF)),
                Expanded(
                  child: _buildLegColumn(
                    i,
                    i < legLists.length ? legLists[i] : const [],
                    isCompleted: isCompleted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_legSelections.every((s) => s != null)) _buildContinueBar(),
      ],
    );
  }

  Widget _buildLegColumn(int legIndex, List<FlightEntity> flights, {required bool isCompleted}) {
    final filtered = _applyFilters(flights);
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: context.h(8), horizontal: context.w(6)),
          alignment: Alignment.center,
          child: Text(
            _legLabel(legIndex),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w800,
              color: const Color(0xff07163B),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(context.w(12)),
                    child: Text(
                      isCompleted ? 'No flights found' : 'Searching…',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: context.fs(11), color: Colors.grey.shade600),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(8)),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final flight = filtered[idx];
                    final isSelected = _legSelections[legIndex]?.resultIndex == (flight.resultIndex ?? '');
                    return Padding(
                      padding: EdgeInsets.only(bottom: context.h(8)),
                      child: _buildColumnFlightCard(
                        flight,
                        isSelected: isSelected,
                        onTap: () => _selectLegColumnFlight(legIndex, flight),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Compact flight card sized for a narrow side-by-side column — the
  /// full-width one-way card (`_buildFlightCardInner`) doesn't fit two per
  /// row, so this is a separate, smaller widget rather than a reused one.
  Widget _buildColumnFlightCard(
    FlightEntity flight, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final departure = _formatTime(flight.departureTime);
    final arrival = _formatTime(flight.arrivalTime);
    final airlineCode = (flight.airlineCode?.isNotEmpty ?? false)
        ? flight.airlineCode!.toUpperCase()
        : 'FL';
    final stopsLabel = _formatStops(flight.stops);
    // Each leg (Onward/Return) is mapped from its own trip in
    // `_rawFlightsForTrip`, so origin/destination already point the right
    // way for that leg — no isRoundTrip/return* fields needed here, just
    // the same name-with-code-fallback pattern the one-way card uses.
    final originLabel =
        flight.originName ?? _locationName(flight.origin ?? '');
    final destLabel =
        flight.destinationName ?? _locationName(flight.destination ?? '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(10)),
        child: Container(
          padding: EdgeInsets.all(context.w(8)),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.AppBlue.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(context.r(16)),
            border: Border.all(
              color: isSelected ? AppColors.AppBlue : AppColors.white,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.05),
                blurRadius: context.w(2),
                offset: Offset(0, context.h(0)),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _airlineLogo(flight, context.w(20)),
                      SizedBox(width: context.w(6)),
                      Expanded(
                        child: Text(
                          _displayFlightNo(flight, codeOverride: airlineCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(10),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff3D3F4A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              departure,
                              style: TextStyle(
                                fontSize: context.fs(13),
                                fontWeight: FontWeight.w800,
                                color: const Color(0xff07163B),
                              ),
                            ),
                            SizedBox(height: context.h(2)),
                            Text(
                              originLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.fs(9),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xffA0A6C2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.w(4)),
                        child: Icon(Icons.arrow_forward, size: context.w(11), color: const Color(0xffB6BEDB)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              arrival,
                              style: TextStyle(
                                fontSize: context.fs(13),
                                fontWeight: FontWeight.w800,
                                color: const Color(0xff07163B),
                              ),
                            ),
                            SizedBox(height: context.h(2)),
                            Text(
                              destLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: context.fs(9),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xffA0A6C2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (stopsLabel.isNotEmpty) ...[
                    SizedBox(height: context.h(4)),
                    Text(
                      stopsLabel,
                      style: TextStyle(
                        fontSize: context.fs(9),
                        color: const Color(0xff9AA2BF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(height: context.h(6)),
                  _flightPriceText(
                    (flight.totalFare ?? 0).toDouble(),
                    flight.currency,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff1663F7),
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: context.w(16),
                    height: context.w(16),
                    decoration: const BoxDecoration(color: Color(0xff16A34A), shape: BoxShape.circle),
                    child: Icon(Icons.check, size: context.w(11), color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLegColumnFlight(int legIndex, FlightEntity flight) {
    setState(() {
      _legSelections[legIndex] = FlightLegSelection(
        orderId: legIndex + 1,
        resultIndex: flight.resultIndex ?? '',
        amount: (flight.totalFare ?? 0).toDouble(),
        flight: flight,
      );
    });
  }

  /// Pre-selects the first flight in every leg column that doesn't have a
  /// pick yet, so round trip / multi-city results aren't blocked on the user
  /// manually tapping every column before Continue appears. The user can
  /// still tap a different card to override the pick.
  void _autoSelectFirstFlights(List<List<FlightEntity>> legLists) {
    // Round trip / special return drive selection through the stepped
    // selector (`_buildRoundTripStepped`) — the user explicitly taps each
    // leg, so don't pre-fill picks here.
    if (_fareTripType.hasReturnLeg) return;
    final toSelect = <int, FlightEntity>{};
    for (var i = 0; i < legLists.length && i < _legSelections.length; i++) {
      if (_legSelections[i] == null && legLists[i].isNotEmpty) {
        toSelect[i] = legLists[i].first;
      }
    }
    if (toSelect.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      toSelect.forEach((i, flight) {
        if (_legSelections[i] == null) _selectLegColumnFlight(i, flight);
      });
    });
  }

  Widget _buildContinueBar() {
    final total = _legSelections.fold<double>(0, (s, sel) => s + (sel?.amount ?? 0));
    final currency = _legSelections.first?.flight.currency;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(10)),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: context.fs(10), color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _convertFlightPrice(total, currency),
                    style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w800, color: const Color(0xff07163B)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: context.h(44),
              child: ElevatedButton(
                onPressed: _showMultiLegDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: context.w(28)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Round trip / special return — Wego-style stepped selector. One full-width
  // list at a time: first the departing flight, then (after a pick) the
  // returning flight, with a summary of the chosen departure and a stepper
  // header. Selection still flows through `_legSelections` /
  // `_selectLegColumnFlight`, so pricing/booking downstream is unchanged.
  // There is no Continue / total bar here — picking the returning flight
  // opens the combined detail popup directly (see `_buildRtFlightCard`).
  // ---------------------------------------------------------------------------
  Widget _buildRoundTripStepped(
    List<List<FlightEntity>> legLists, {
    required bool isCompleted,
  }) {
    final departSel = _legSelections.isNotEmpty ? _legSelections[0] : null;
    final step = (departSel != null && _rtStep == 1) ? 1 : 0;
    final legIndex = step;
    final legFlights =
        legIndex < legLists.length ? legLists[legIndex] : const <FlightEntity>[];
    final filtered = _applyFilters(legFlights);

    // Same layout contract as one-way (`_buildMainContent`): the list scrolls
    // full-bleed and the Sort / Non Stop / Filter bar floats over it with no
    // fixed white strip. Extra bottom padding keeps the last card clear of
    // the floating bar.
    return Stack(
      children: [
        Column(
          children: [
            // Glide the departure summary in/out with the stepper.
            AnimatedSize(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: (step == 1 && departSel != null)
                  ? _buildRtDepartureSummary(departSel.flight)
                  : const SizedBox(width: double.infinity),
            ),
            _buildRtStepper(step),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(context.w(16)),
                        child: Text(
                          isCompleted ? 'No flights found' : 'Searching…',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.fs(12),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        context.h(2),
                        0,
                        context.h(84),
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final flight = filtered[i];
                        final selected =
                            _legSelections[legIndex]?.resultIndex ==
                                (flight.resultIndex ?? '');
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.w(14),
                            context.h(6),
                            context.w(14),
                            context.h(6),
                          ),
                          child: _buildRtFlightCard(
                            flight,
                            legIndex: legIndex,
                            selected: selected,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildOneWayActionBar(),
        ),
      ],
    );
  }

  Widget _buildRtStepper(int step) {
    String fmtDate(DateTime? d) {
      if (d == null) return '';
      // Match the mock's "04 Sept 2026, Fri" (intl's MMM is "Sep").
      return DateFormat('dd MMM yyyy, EEE')
          .format(d)
          .replaceFirst('Sep ', 'Sept ');
    }

    final departDate = fmtDate(_selectedDate ?? widget.date);
    final returnDate = fmtDate(_returnDate);

    // Single 0..1 driver for the whole card: 0 = departing step, 1 = returning
    // step. TweenAnimationBuilder eases every dependent value (banner slide,
    // chip widths, circle/text colours, date reveal) together — the Wego-style
    // glide instead of an instant swap.
    final target = step == 1 ? 1.0 : 0.0;

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(8),
        context.w(16),
        context.h(8),
      ),
      height: context.h(45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: target),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Light-blue banner that slides from the departing side to the
              // returning side, keeping its `>` chevron edges.
              Positioned.fill(
                child: CustomPaint(
                  painter: _RtStepBannerPainter(
                    t: t,
                    bannerColor: const Color(0xFFCDE8FB),
                    seamColor: const Color(0xFFDCE3EC),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: Row(
                  children: [
                    // Chip flex tracks the banner's split (56/44 ↔ 44/56) so
                    // the active chip's content lines up with the blue band
                    // in both directions.
                    _rtStepChip(
                      index: 1,
                      label: t < 0.5 ? 'Select Departing Flight' : 'Depart',
                      subLabel: departDate,
                      fillT: 1 - t,
                      flex: ui.lerpDouble(56, 44, t)!.round(),
                      onTap:
                          step == 1 ? () => setState(() => _rtStep = 0) : null,
                    ),
                    _rtStepChip(
                      index: 2,
                      label:
                          t < 0.5 ? 'Return' : 'Select Returning Flight',
                      subLabel: returnDate,
                      fillT: t,
                      flex: ui.lerpDouble(44, 56, t)!.round(),
                      onTap: null,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// One step of the round trip stepper. [fillT] is this step's active
  /// progress (0 = idle grey, 1 = active blue) — every visual is lerped
  /// across it so the transition glides.
  Widget _rtStepChip({
    required int index,
    required String label,
    String? subLabel,
    required double fillT,
    required int flex,
    VoidCallback? onTap,
  }) {
    final double f = fillT.clamp(0.0, 1.0);
    final circleColor = Color.lerp(AppColors.subhead, AppColors.AppBlue, f)!;
    final labelColor = Color.lerp(AppColors.subhead, AppColors.black, f)!;
    final double circleSize = ui.lerpDouble(18, 24, f)!;

    return Expanded(
      flex: flex < 1 ? 1 : flex,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Align(
          // Active step hugs the start of its (wider) side; idle step
          // sits centred in its side.
          alignment:
              Alignment.lerp(Alignment.center, Alignment.centerLeft, f)!,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Leading inset grows with the fill so the active circle clears
              // the banner's chevron notch instead of sitting on the seam.
              SizedBox(width: context.w(ui.lerpDouble(8, 18, f)!)),
              Container(
                width: context.w(circleSize),
                height: context.w(circleSize),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: context.fs(ui.lerpDouble(9, 11, f)!),
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(width: context.w(ui.lerpDouble(6, 9, f)!)),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(ui.lerpDouble(9, 10, f)!),
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    if (subLabel != null && subLabel.isNotEmpty)
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topLeft,
                          heightFactor: f,
                          child: Opacity(
                            opacity: f,
                            child: Padding(
                              padding: EdgeInsets.only(top: context.h(1)),
                              child: Text(
                                subLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.fs(10),
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8A8D94),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Keeps the idle chip's label off the card edge now that the
              // row itself has no trailing padding.
              SizedBox(width: context.w(14)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildRtDepartureSummary(FlightEntity f) {
    final origin = (f.origin ?? '').trim().toUpperCase();
    final dest = (f.destination ?? '').trim().toUpperCase();

    String dateStr = '';
    try {
      dateStr = DateFormat('dd MMM yyyy, EEE')
          .format(DateTime.parse(f.departureTime ?? ''))
          .replaceFirst('Sep ', 'Sept ');
    } catch (_) {}
    final durStr = _formatDuration(
        f.duration != null ? int.tryParse(f.duration!) : null);
    final stopStr =
        (f.stops ?? 0) <= 0 ? 'Direct' : _formatStops(f.stops);

    final codeStyle = TextStyle(
      fontSize: context.fs(12),
      fontWeight: FontWeight.w500,
      color: AppColors.black,
    );
    final timeStyle = TextStyle(
      fontSize: context.fs(8),
      fontWeight: FontWeight.w500,
      color: AppColors.subhead,
    );
    final metaStyle = TextStyle(
      fontSize: context.fs(8),
      fontWeight: FontWeight.w500,
      color: AppColors.subhead,
    );

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(8),
        context.w(14),
        context.h(4),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(color: AppColors.AppBlue, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _airlineLogo(
              f,
              context.w(28),
              bg: const Color(0xFF1E1E5A),
              radius: context.r(8),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: origin, style: codeStyle),
                        TextSpan(
                          text: ' ${_formatTime(f.departureTime)}',
                          style: timeStyle,
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(7),
                            ),
                            child: Image.asset(
                              'assets/NewIcons/flightRound.png',
                              width: context.w(13.33),
                              height: context.w(13.1),
                              color: AppColors.AppBlue,
                            ),
                          ),
                        ),
                        TextSpan(text: dest, style: codeStyle),
                        TextSpan(
                          text: ' ${_formatTime(f.arrivalTime)}',
                          style: timeStyle,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.h(3)),
                  Text.rich(
                    TextSpan(
                      style: metaStyle,
                      children: [
                        if (dateStr.isNotEmpty) TextSpan(text: '$dateStr  |  '),
                        if (durStr != '0') TextSpan(text: '$durStr  |  '),
                        TextSpan(
                          text: stopStr,
                          style: const TextStyle(
                            color: Color(0xFFE23A2F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(10)),
            GestureDetector(
              onTap: () => setState(() => _rtStep = 0),
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Change',
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.AppBlue,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.AppBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Round trip result card — the same [FlightCard] widget the one-way list
  /// uses, wrapped so a tap selects the leg (and, on the departing step,
  /// advances to the returning step) and the current pick shows a blue ring.
  Widget _buildRtFlightCard(
    FlightEntity flight, {
    required int legIndex,
    required bool selected,
  }) {
    final target = CurrencyConverter.getPreferredCurrency();
    final priceText = '${CurrencyConverter.getSymbol(target)} '
        '${_convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency)}';
    final airlineCode = (flight.airlineCode?.isNotEmpty ?? false)
        ? flight.airlineCode!.toUpperCase()
        : (flight.airlineName?.isNotEmpty ?? false)
            ? flight.airlineName!.substring(0, 1).toUpperCase()
            : 'FL';

    return GestureDetector(
      onTap: () {
        _selectLegColumnFlight(legIndex, flight);
        if (legIndex == 0) {
          // Departing leg picked — advance to the returning step.
          setState(() => _rtStep = 1);
        } else if (_legSelections.every((s) => s != null)) {
          // Returning leg picked and both legs are set — open the combined
          // detail popup directly (replaces the old Continue bar).
          _showMultiLegDetails();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.r(18)),
          border: Border.all(
            color: selected ? AppColors.AppBlue : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: FlightCard(
          airlineName: flight.airlineName ?? 'Airline',
          flightNumber: _displayFlightNo(flight, codeOverride: airlineCode),
          logo: _airlineLogo(flight, context.w(46)),
          priceText: priceText,
          departureCity:
              flight.originName ?? _locationName(flight.origin ?? ''),
          departureCode: (flight.origin ?? '').trim().toUpperCase(),
          departureTime: _formatTime(flight.departureTime),
          arrivalCity:
              flight.destinationName ?? _locationName(flight.destination ?? ''),
          arrivalCode: (flight.destination ?? '').trim().toUpperCase(),
          arrivalTime: _formatTime(flight.arrivalTime),
          duration: _formatDuration(
              flight.duration != null ? int.tryParse(flight.duration!) : null),
          stopsLabel: _formatStops(flight.stops),
        ),
      ),
    );
  }


  Widget _buildDateStrip() {
    final today = DateUtils.dateOnly(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollSelectedDateIntoView(),
    );
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: SizedBox(
        height: context.h(42),
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
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(14),
                  vertical: context.h(10),
                ),
                margin: EdgeInsets.only(right: context.w(8)),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.AppBlue.withOpacity(0.1)  // Light blue background when selected
                      : Colors.white,
                  borderRadius: BorderRadius.circular(context.r(8)),
                  border: Border.all(
                    color: selected
                        ? AppColors.AppBlue  // Blue border when selected
                        : const Color(0xFFCCCCCC),  // Light grey border when unselected
                    width: 1,
                  ),
                  // boxShadow: selected
                  //     ? [
                  //   BoxShadow(
                  //     color: AppColors.AppBlue.withOpacity(0.15),
                  //     blurRadius: context.w(6),
                  //     offset: Offset(0, context.h(2)),
                  //   ),
                  // ]
                  //     : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // DateFormat('EEE').format(date), // "Mon"
                      '${DateFormat('EEE').format(date)},',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? AppColors.AppBlue  // Blue text when selected
                            : AppColors.black,
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Text(
                      DateFormat('d MMM').format(date), // "24 Aug"
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? AppColors.AppBlue  // Blue text when selected
                            : AppColors.black,
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
        _selectedStops.isNotEmpty ||
        _durationRange != null ||
        _filterRefundable ||
        _filterNonRefundable ||
        // _nonStopOnly ||
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
  // Number of placeholder cards shown at the end of the list while
  // GetExpSearch is still polling for more results.
  static const int _loadingMoreSkeletonCount = 2;

  Widget _buildFlightList(
    List<_FlightGroup> groups,
    int filteredCount,
    int totalCount, {
    required bool isCompleted,
  }) {
    if (groups.isEmpty) {
      return _buildNoResultsState();
    }
    final skeletonCount = isCompleted ? 0 : _loadingMoreSkeletonCount;
    return Container(
      color: AppColors.white,
      child: CustomScrollView(
        slivers: [
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
            // Extra bottom room so the last card clears the floating
            // Sort / Non Stop / Filter bar.
            padding: EdgeInsets.fromLTRB(
              context.w(10),
              0,
              context.w(10),
              context.h(78),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => index < groups.length
                    ? _buildGroupCard(groups[index])
                    : _buildFlightCardSkeleton(),
                childCount: groups.length + skeletonCount,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder card shown at the end of the results list while more
  /// flights are still being fetched (poll not yet complete) — same
  /// dimensions/shape as a real flight card so it doesn't jump the layout
  /// once real results replace it. Static grey blocks, matching this
  /// codebase's existing shimmer-card convention (see
  /// travel_stories.dart's _buildHorizontalShimmerCard).
  Widget _buildFlightCardSkeleton() {
    Widget bar({required double width, double height = 10, double radius = 4}) {
      return Container(
        width: width,
        height: context.h(height),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(context.r(radius)),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(color: const Color(0xffE9EDF6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.fieldBorder.withValues(alpha: 0.05),
              blurRadius: context.w(10),
              offset: Offset(0, context.h(4)),
            ),
          ],
        ),
        padding: EdgeInsets.all(context.w(12)),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: context.w(34),
                  height: context.w(34),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      bar(width: context.w(110)),
                      SizedBox(height: context.h(6)),
                      bar(width: context.w(70), height: 8),
                    ],
                  ),
                ),
                bar(width: context.w(48), height: 16, radius: 6),
              ],
            ),
            SizedBox(height: context.h(16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                bar(width: context.w(46), height: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(10)),
                    child: bar(width: double.infinity, height: 1, radius: 0),
                  ),
                ),
                bar(width: context.w(46), height: 16),
              ],
            ),
          ],
        ),
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
      title: 'Get 80% OFF with HDFC Credit Cards',
      code: 'TESTING',
      icon: Icons.local_offer_rounded,
    ),
    _FlightOffer(
      title: 'Up to ₹2,000 OFF on your first booking',
      code: 'TESTING-1',
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
            fontSize: context.fs(10),
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
              _nonStopOnly = false;
              _selectedAirlines =
                  _allFlights.map((f) => f.airlineName ?? 'Unknown').toSet();
              _priceRange = RangeValues(_minPrice, _maxPrice);
              _userCustomizedAirlineFilter = false;
            }),
            child: Text(
              "Clear Filters",
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: AppColors.AppBlue,
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
                      child: _buildExpandedFlightCard(f),
                    ))
                .toList(),
        ],
      ),
    );
  }

  /// One-way primary card — the standalone [FlightCard] widget styled per the
  /// Figma reference. The tap target, the inline offer strip and the
  /// "N more flights at this price" toggle all behave exactly as they did in
  /// the old inline layout; only the visual card body changed.
  Widget _buildOneWayFlightCard(
    FlightEntity flight, {
    required int extraCount,
    required bool isExpanded,
    VoidCallback? onMoreTap,
  }) {
    final target = CurrencyConverter.getPreferredCurrency();
    final priceText =
        '${CurrencyConverter.getSymbol(target)} '
        '${_convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency)}';

    final airlineCode = (flight.airlineCode?.isNotEmpty ?? false)
        ? flight.airlineCode!.toUpperCase()
        : (flight.airlineName?.isNotEmpty ?? false)
        ? flight.airlineName!.substring(0, 1).toUpperCase()
        : 'FL';

    Widget? footer;
    if (extraCount > 0) {
      footer = Padding(
        padding: EdgeInsets.only(top: context.h(12)),
        child: GestureDetector(
          onTap: onMoreTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(7),
            ),
            decoration: BoxDecoration(
              color: AppColors.AppBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(context.r(10)),
              border: Border.all(
                color: AppColors.AppBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [


                Text(
                  isExpanded
                      ? 'Hide extra flights'
                      : '$extraCount more flight${extraCount > 1 ? 's' : ''} at the same price',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.AppBlue,
                  ),
                ),
                SizedBox(width: context.w(5)),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: context.w(16),
                  color: AppColors.AppBlue,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onFlightCardTap(flight),
      behavior: HitTestBehavior.opaque,
      child: FlightCard(
        airlineName: flight.airlineName ?? 'Airline',
        flightNumber: _displayFlightNo(flight, codeOverride: airlineCode),
        logo: _airlineLogo(flight, context.w(46)),
        priceText: priceText,
        departureCity: flight.originName ??
            _locationName(flight.origin ?? widget.fromCode),
        departureCode:
            (flight.origin ?? widget.fromCode).trim().toUpperCase(),
        departureTime: _formatTime(flight.departureTime),
        arrivalCity: flight.destinationName ??
            _locationName(flight.destination ?? widget.toCode),
        arrivalCode:
            (flight.destination ?? widget.toCode).trim().toUpperCase(),
        arrivalTime: _formatTime(flight.arrivalTime),
        duration: _formatDuration(
            flight.duration != null ? int.tryParse(flight.duration!) : null),
        stopsLabel: _formatStops(flight.stops),
        footer: footer,
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

    // One-way results use the standalone [FlightCard] widget (Figma design).
    // Round trips keep the existing two-leg layout below, unchanged.
    if (!isRoundTrip) {
      return _buildOneWayFlightCard(
        flight,
        extraCount: extraCount,
        isExpanded: isExpanded,
        onMoreTap: onMoreTap,
      );
    }

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
          onTap: () => _onFlightCardTap(flight),
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
                            _displayFlightNo(flight, codeOverride: airlineCode),
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
                    _flightPriceText(
                      (flight.totalFare ?? 0).toDouble(),
                      flight.currency,
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
                        code: flight.originName ??
                            _locationName(flight.origin ?? widget.fromCode),
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
                        code: flight.destinationName ??
                            _locationName(flight.destination ?? widget.toCode),
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

  /// Expanded flight card that uses the same FlightCard widget as primary cards
  Widget _buildExpandedFlightCard(FlightEntity flight) {
    final target = CurrencyConverter.getPreferredCurrency();
    final priceText =
        '${CurrencyConverter.getSymbol(target)} '
        '${_convertFlightPrice((flight.totalFare ?? 0).toDouble(), flight.currency)}';

    final airlineCode = (flight.airlineCode?.isNotEmpty ?? false)
        ? flight.airlineCode!.toUpperCase()
        : (flight.airlineName?.isNotEmpty ?? false)
        ? flight.airlineName!.substring(0, 1).toUpperCase()
        : 'FL';

    return GestureDetector(
      onTap: () => _onFlightCardTap(flight),
      behavior: HitTestBehavior.opaque,
      child: FlightCard(
        airlineName: flight.airlineName ?? 'Airline',
        flightNumber: _displayFlightNo(flight, codeOverride: airlineCode),
        logo: _airlineLogo(flight, context.w(46), isNavy: true), // Pass isNavy: true
        priceText: priceText,
        departureCity: flight.originName ??
            _locationName(flight.origin ?? widget.fromCode),
        departureCode:
        (flight.origin ?? widget.fromCode).trim().toUpperCase(),
        departureTime: _formatTime(flight.departureTime),
        arrivalCity: flight.destinationName ??
            _locationName(flight.destination ?? widget.toCode),
        arrivalCode:
        (flight.destination ?? widget.toCode).trim().toUpperCase(),
        arrivalTime: _formatTime(flight.arrivalTime),
        duration: _formatDuration(
            flight.duration != null ? int.tryParse(flight.duration!) : null),
        stopsLabel: _formatStops(flight.stops),
        footer: null, // No footer for expanded cards
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
          originCode: flight.originName ??
              _locationName(flight.origin ?? widget.fromCode),
          destCode: flight.destinationName ??
              _locationName(flight.destination ?? widget.toCode),
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
          originCode: flight.returnOriginName ??
              _locationName(
                  flight.returnOrigin ?? flight.destination ?? widget.toCode),
          destCode: flight.returnDestinationName ??
              _locationName(
                  flight.returnDestination ?? flight.origin ?? widget.fromCode),
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
  // Only ever wired to `_buildFlightCardInner`'s onTap, which itself is only
  // ever built by `_buildMainContent` — the plain one-way path. RT/RS/IM/DM
  // use `_buildColumnFlightCard` instead, which selects on tap rather than
  // opening this popup (see `_selectLegColumnFlight`/`_showMultiLegDetails`).
  void _onFlightCardTap(FlightEntity flight) => _showFlightDetails(flight);

  void _showFlightDetails(FlightEntity flight) {
    FlightDetailsPopup.show(
      context,
      tui: _currentTui,
      resultIndex: flight.resultIndex ?? '',
      amount: (flight.totalFare ?? 0).toDouble(),
      airlineName: flight.airlineName ?? "Unknown",
      airlineCode: flight.airlineCode ?? "--",
      flightNumber: _displayFlightNo(flight),
      fromCode: flight.origin ?? "--",
      toCode: flight.destination ?? "--",
      departureTime: _formatTime(flight.departureTime),
      arrivalTime: _formatTime(flight.arrivalTime),
      traceId: flight.traceId,
      duration: "${flight.duration ?? '--'} min",
      price: _convertFlightPrice(
        (flight.totalFare ?? 0).toDouble(),
        flight.currency,
      ),
      travellerCount: widget.travellers,
      fareFamilyOptions: flight.fareFamilyOptions,
    );
  }

  /// Opens the combined detail popup once every column has a pick — the
  /// only popup shown for RT/RS/IM/DM, triggered from the Continue bar
  /// rather than per-leg. Leg 1's fare-family options (Choose Your Fare)
  /// are still offered here; legs 2..N book with whichever fare was tapped
  /// in their column.
  void _showMultiLegDetails() {
    final selections = _legSelections.whereType<FlightLegSelection>().toList();
    if (selections.length != _legCount) return;
    final first = selections.first;
    FlightDetailsPopup.show(
      context,
      tui: _currentTui,
      resultIndex: first.resultIndex,
      amount: first.amount,
      airlineName: first.flight.airlineName ?? "Unknown",
      airlineCode: first.flight.airlineCode ?? "--",
      flightNumber: _displayFlightNo(first.flight),
      fromCode: first.flight.origin ?? "--",
      toCode: first.flight.destination ?? "--",
      departureTime: _formatTime(first.flight.departureTime),
      arrivalTime: _formatTime(first.flight.arrivalTime),
      traceId: first.flight.traceId,
      duration: "${first.flight.duration ?? '--'} min",
      price: _convertFlightPrice(first.amount, first.flight.currency),
      travellerCount: widget.travellers,
      fareFamilyOptions: first.flight.fareFamilyOptions,
      tripType: widget.fareType,
      additionalLegs: selections.sublist(1),
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
              _userCustomizedAirlineFilter = false;
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
  /// Maps an airport IATA code back to the full location name the user
  /// searched with (e.g. "DEL" -> "New Delhi"), so cards show the readable
  /// city/airport name instead of the bare code. Falls back to the code
  /// itself for anything outside the searched origin/destination pair.
  String _locationName(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return code;
    if (normalized == widget.fromCode.trim().toUpperCase()) {
      return widget.from.isNotEmpty ? widget.from : widget.fromAirport;
    }
    if (normalized == widget.toCode.trim().toUpperCase()) {
      return widget.to.isNotEmpty ? widget.to : widget.toAirport;
    }
    return code;
  }

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

  /// A flight card's fare with a small "/adult" suffix, so the headline
  /// number is unambiguous about who it covers. The amount, its formatting
  /// and [style] are exactly what the plain `Text` used before — the suffix
  /// is drawn smaller and lighter so it reads as a unit on the price rather
  /// than a second price.
  Widget _flightPriceText(
    double amount,
    String? apiCurrency, {
    required TextStyle style,
  }) {
    final baseSize = style.fontSize ?? context.fs(14);
    return Text.rich(
      TextSpan(
        text: _convertFlightPrice(amount, apiCurrency),
        style: style,
        children: [
          TextSpan(
            text: ' /adult',
            style: style.copyWith(
              fontSize: baseSize * 0.6,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
  Widget _airlineLogo(
    FlightEntity flight,
    double size, {
    bool isNavy = false,
    Color? bg,
    double? radius,
  }) {
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

    // If isNavy is true (or an explicit bg is given), use a filled tile.
    if (isNavy || bg != null) {
      return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg ?? AppColors.AppBlue,
          borderRadius: BorderRadius.circular(radius ?? context.r(8)),
        ),
        child: code.isEmpty
            ? initialsTile()
            : CachedNetworkImage(
          imageUrl: 'https://images.kiwi.com/airlines/64/$code.png',
          fit: BoxFit.contain,
          placeholder: (_, __) => initialsTile(),
          errorWidget: (_, __, ___) => initialsTile(),
        ),
      );
    }

    // Default style (white background with border) for other flight types
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
      ),
      child: code.isEmpty
          ? initialsTile()
          : CachedNetworkImage(
        imageUrl: 'https://images.kiwi.com/airlines/64/$code.png',
        fit: BoxFit.contain,
        placeholder: (_, __) => initialsTile(),
        errorWidget: (_, __, ___) => initialsTile(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painters
// ---------------------------------------------------------------------------

/// Round trip stepper background: a light-blue band with `>` chevron edges
/// that slides from the departing side ([t] = 0) to the returning side
/// ([t] = 1). Anything past a container edge is clipped away, so the band
/// reads as anchored to that edge at the extremes. See `_buildRtStepper`.
class _RtStepBannerPainter extends CustomPainter {
  final double t;
  final Color bannerColor;
  final Color seamColor;

  _RtStepBannerPainter({
    required this.t,
    required this.bannerColor,
    required this.seamColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;
    final chev = h * 0.34; // chevron depth

    // Both edges travel left→right; the parent clips whatever spills past 0/w.
    final leftX = ui.lerpDouble(-chev, w * 0.44, t)!;
    final rightX = ui.lerpDouble(w * 0.56, w + chev, t)!;

    final banner = Path()
      ..moveTo(leftX, 0)
      ..lineTo(rightX, 0)
      ..lineTo(rightX + chev, mid)
      ..lineTo(rightX, h)
      ..lineTo(leftX, h);
    if (leftX > 0.5) banner.lineTo(leftX + chev, mid);
    banner.close();
    canvas.drawPath(banner, Paint()..color = bannerColor);

    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = seamColor;
    if (rightX < w - 0.5) {
      canvas.drawPath(
        Path()
          ..moveTo(rightX, 0)
          ..lineTo(rightX + chev, mid)
          ..lineTo(rightX, h),
        seam,
      );
    }
    if (leftX > 0.5) {
      canvas.drawPath(
        Path()
          ..moveTo(leftX, 0)
          ..lineTo(leftX + chev, mid)
          ..lineTo(leftX, h),
        seam,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RtStepBannerPainter old) =>
      old.t != t ||
      old.bannerColor != bannerColor ||
      old.seamColor != seamColor;
}

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
