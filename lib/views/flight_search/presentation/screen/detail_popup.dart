import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:dio/dio.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/AKFlightInfo/domain/entity/AKFlightInfo_entity.dart';
import 'package:wander_nova/views/AKFlightInfo/presentation/bloc/AKFlightInfo_bloc.dart';
import 'package:wander_nova/views/AKFlightInfo/presentation/bloc/AKFlightInfo_event.dart';
import 'package:wander_nova/views/AKFlightInfo/presentation/bloc/AKFlightInfo_state.dart';
import 'package:wander_nova/views/AKGetSPricer/data/model/AKGetSPricer_model.dart';
import 'package:wander_nova/views/AKGetSPricer/domain/entity/AKGetSPricer_entity.dart';
import 'package:wander_nova/views/AKGetSPricer/presentation/bloc/AKGetSPricer_bloc.dart';
import 'package:wander_nova/views/AKGetSPricer/presentation/bloc/AKGetSPricer_event.dart';
import 'package:wander_nova/views/AKGetSPricer/presentation/bloc/AKGetSPricer_state.dart';
import 'package:wander_nova/views/AKSmartPricer/domain/entity/AKSmartPricer_entity.dart';
import 'package:wander_nova/views/AKSmartPricer/presentation/bloc/AKSmartPricer_bloc.dart';
import 'package:wander_nova/views/AKSmartPricer/presentation/bloc/AKSmartPricer_event.dart';
import 'package:wander_nova/views/AKSmartPricer/presentation/bloc/AKSmartPricer_state.dart';
import 'package:wander_nova/views/AKAcceptFareChange/domain/entity/AKAcceptFareChange_entity.dart';
import 'package:wander_nova/views/AKAcceptFareChange/domain/usecase/AKAcceptFareChange_usecase.dart';
import 'package:wander_nova/views/AKFareRule/domain/entity/AKFareRule_entity.dart';
import 'package:wander_nova/views/AKFareRule/presentation/bloc/AKFareRule_bloc.dart';
import 'package:wander_nova/views/AKFareRule/presentation/bloc/AKFareRule_event.dart';
import 'package:wander_nova/views/AKFareRule/presentation/bloc/AKFareRule_state.dart';
import 'package:wander_nova/views/AKFareRule/presentation/screen/ak_fare_rule_popup.dart';
import 'package:wander_nova/views/AKFareFamilyDetails/domain/entity/AKFareFamilyDetails_entity.dart';
import 'package:wander_nova/views/AKFareFamilyDetails/presentation/bloc/AKFareFamilyDetails_bloc.dart';
import 'package:wander_nova/views/AKFareFamilyDetails/presentation/bloc/AKFareFamilyDetails_event.dart';
import 'package:wander_nova/views/AKFareFamilyDetails/presentation/bloc/AKFareFamilyDetails_state.dart';
import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/views/flight_search/domain/entities/flight_entity.dart'
    show FareFamilyIndexEntity;
import 'package:wander_nova/views/flight_search/domain/entities/fare_trip_type.dart';
import 'package:wander_nova/views/AKSmartPricer/domain/usecase/AKSmartPricer_usecase.dart';
import 'package:wander_nova/views/AKGetSPricer/domain/usecase/AKGetSPricer_usecase.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
import 'package:wander_nova/common_widgets/currency_scope.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/newUIWidgets/fare_breakup_sheet.dart';

import '../../../../core/constants/urls.dart';

class FlightDetailsPopup extends StatefulWidget {
  final String tui;
  final String resultIndex;

  /// Gross/retail fare — shown to the user (GrossFare from search).
  final double amount;

  /// Net/agent fare — sent to Akbar's SmartPricer API (NetFare from search).
  final double netAmount;
  final String airlineName;
  final String airlineCode;
  final String flightNumber;
  final String fromCode;
  final String toCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String price;
  final String? traceId;
  final int travellerCount;

  /// The SearchCard's passenger split. Threaded through so the booking form
  /// can render one Adult / Child / Infant block per selected passenger
  /// instead of guessing from [travellerCount].
  final int adultCount;
  final int childCount;
  final int infantCount;

  final List<FareFamilyIndexEntity>? fareFamilyOptions;
  final String tripType;
  final List<FlightLegSelection> additionalLegs;

  /// Session ID from MultiCity/Search/ — required for DM pricing and booking.
  final String? searchSessionId;

  /// IM only: each package's legs 2..N keyed by ReturnIdentifier. Picking a
  /// different leg-1 fare swaps [additionalLegs] for that fare's partners.
  final Map<int, List<FlightLegSelection>> imPartnerLegs;

  const FlightDetailsPopup({
    super.key,
    required this.tui,
    required this.resultIndex,
    required this.amount,
    required this.netAmount,
    required this.airlineName,
    required this.airlineCode,
    required this.flightNumber,
    required this.fromCode,
    required this.toCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    this.traceId,
    this.travellerCount = 1,
    this.adultCount = 0,
    this.childCount = 0,
    this.infantCount = 0,
    this.fareFamilyOptions,
    this.tripType = 'ON',
    this.additionalLegs = const [],
    this.searchSessionId,
    this.imPartnerLegs = const {},
  });

  static void show(
    BuildContext context, {
    required String tui,
    required String resultIndex,
    required double amount,
    required double netAmount,
    required String airlineName,
    required String airlineCode,
    required String flightNumber,
    required String fromCode,
    required String toCode,
    required String departureTime,
    required String arrivalTime,
    required String duration,
    required String price,
    String? traceId,
    int travellerCount = 1,
    int adultCount = 0,
    int childCount = 0,
    int infantCount = 0,
    List<FareFamilyIndexEntity>? fareFamilyOptions,
    String tripType = 'ON',
    List<FlightLegSelection> additionalLegs = const [],
    String? searchSessionId,
    Map<int, List<FlightLegSelection>> imPartnerLegs = const {},
  }) {
    // Was a `showModalBottomSheet` — now a full screen (see class doc) so the
    // fare-options flow gets its own back-stack entry instead of a dismissible
    // sheet. Same static `show(...)` call site/signature everywhere, so
    // nothing calling this needed to change.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlightDetailsPopup(
          tui: tui,
          resultIndex: resultIndex,
          amount: amount,
          netAmount: netAmount,
          airlineName: airlineName,
          airlineCode: airlineCode,
          flightNumber: flightNumber,
          fromCode: fromCode,
          toCode: toCode,
          departureTime: departureTime,
          arrivalTime: arrivalTime,
          duration: duration,
          price: price,
          traceId: traceId,
          travellerCount: travellerCount,
          adultCount: adultCount,
          childCount: childCount,
          infantCount: infantCount,
          fareFamilyOptions: fareFamilyOptions,
          tripType: tripType,
          additionalLegs: additionalLegs,
          searchSessionId: searchSessionId,
          imPartnerLegs: imPartnerLegs,
        ),
      ),
    );
  }

  @override
  State<FlightDetailsPopup> createState() => _FlightDetailsPopupState();
}

class _FlightDetailsPopupState extends State<FlightDetailsPopup>
    with SingleTickerProviderStateMixin {
  // Figma design tokens (Wander Nova app, "aIR CLICK eco" frame).
  static const _title900 = Color(0xFF111527);
  static const _stroke = Color(0xFFCCCCCC);

  late final AkFlightInfoBloc _bloc;
  late final AkSmartPricerBloc _smartPricerBloc;
  late final AkGetSPricerBloc _pricerBloc;
  late final AkFareRuleBloc _fareRuleBloc;
  late final AkFareFamilyDetailsBloc _fareFamilyDetailsBloc;

  // Labels fetched from FareFamilyDetails API, keyed by result-index.
  // Empty until the API responds; UI falls back to rank-based labels until then.
  Map<String, String> _fareFamilyLabels = {};
  // Baggage allowances from FareFamilyDetails, keyed by result-index.
  // Each entry: {'checkin': '15 Kg', 'cabin': '7 Kg'} (either may be null).
  Map<String, Map<String, String?>> _fareFamilyBaggage = {};

  bool _smartPricerRequested = false;
  bool _pricerRequested = false;
  String? _sessionId;
  String? _pricingTui;
  AkGetSPricerEntity? _pricerData;
  bool _fareChangeAccepted = false;
  late String _selectedIndex;

  /// Gross fare — shown to the user.
  late double _selectedAmount;

  /// Net/agent fare — sent to Akbar's pricing APIs (SmartPricer, FlightInfo,
  /// FareRule, FareFamilyDetails). Falls back to [_selectedAmount].
  late double _selectedNetAmount;

  /// Legs 2..N as currently chosen. Seeded from what the results screen
  /// picked, then rewritten when the traveller switches that leg's fare on
  /// its own tab — so the pricing calls and the totals follow the pick
  /// instead of the fare the results list happened to open with. Leg 1 stays
  /// in [_selectedIndex]/[_selectedAmount], leaving the one-way path alone.
  late List<FlightLegSelection> _additionalLegs;
  bool _switchingFare = false;
  bool _committing = false;

  // Last successfully loaded FlightInfo + GetSPricer data — kept so that
  // during a fare switch (when AkFlightInfoBloc re-enters Loading) we can
  // keep showing the route card and shimmer only the fare-detail sections
  // instead of replacing the whole screen with _placeholderContent.
  AkFlightInfoEntity? _cachedFlightInfo;
  AkGetSPricerEntity? _cachedPricerData;

  // Akbar's SmartPricer(preview=false) generates a one-use TUI that is
  // consumed by GetSPricer. Calling it again on the same search TUI (e.g.
  // when the user goes back from traveller details and taps "Book Now" again)
  // returns a "TUI already used" error. Once _commitPricing() succeeds we
  // cache the result here and skip the re-call on subsequent Book Now taps;
  // it is cleared whenever the user switches fare.
  bool _commitDone = false;

  // RT only: set to true once AkFlightInfoLoaded fires. Book Now for RT is
  // gated on this instead of SmartPricer/GetSPricer (which are not called on
  // RT init — the single allowed SmartPricer(preview=false) call is reserved
  // for _commitPricing() when the user taps Book Now).
  bool _flightInfoLoaded = false;

  // "View flight details" expand/collapse under the route card.
  bool _flightDetailsExpanded = false;

  // Round trip / multi-city only (Figma: "aIR CLICK eco round flight 1") —
  // which leg's route card the ONWARD/RETURN tab bar is showing. One-way
  // never renders the tab bar, so this stays unused/at 0 for it.
  int _selectedLegTab = 0;

  // "Price Drop Protection" toggle per fare-option index — each MMT-style
  // card has its own independent toggle. Keyed by FareFamilyIndexEntity.index.
  final Map<String, bool> _priceDropProtection = {};

  // Animation controllers for smooth transitions
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;

  /// The fare families of whichever leg's tab is open. Each leg carries its
  /// own list on its [FlightEntity]; reading leg 1's for every tab is what
  /// made the RETURN tab quote the outbound flight's fares.
  List<FareFamilyIndexEntity> get _fareOptions {
    final tab = _activeLegTab;
    var options = tab == 0
        ? widget.fareFamilyOptions
        : _additionalLegs[tab - 1].flight.fareFamilyOptions;
    // IM: only offer leg-1 fares whose package partners are known — any
    // other one can't be priced as a whole journey.
    if (tab == 0 && options != null && widget.imPartnerLegs.isNotEmpty) {
      options = options
          .where((o) => widget.imPartnerLegs.containsKey(o.returnIdentifier))
          .toList();
    }
    if (options != null && options.isNotEmpty) return options;
    return [
      FareFamilyIndexEntity(
        index: _activeLegIndex,
        amount: _activeLegAmount,
        refundable: true,
      ),
    ];
  }

  /// [_selectedLegTab] clamped to the legs that actually exist, since the
  /// tab bar and the leg list are rebuilt independently.
  int get _activeLegTab => _additionalLegs.isEmpty
      ? 0
      : _selectedLegTab.clamp(0, _additionalLegs.length);

  /// The open leg's chosen fare — leg 1 from [_selectedIndex], the rest from
  /// [_additionalLegs].
  String get _activeLegIndex {
    final tab = _activeLegTab;
    return tab == 0 ? _selectedIndex : _additionalLegs[tab - 1].resultIndex;
  }

  double get _activeLegAmount {
    final tab = _activeLegTab;
    return tab == 0 ? _selectedAmount : _additionalLegs[tab - 1].amount;
  }

  /// Every fare on this screen is Akbar's whole-party amount — the figure the
  /// traveller actually pays — unlike the result cards behind it, which show
  /// one traveller's share. So the suffix names who the number covers instead
  /// of claiming "/adult" for a party of several.
  String get _fareCoverageLabel {
    final pax = widget.travellerCount < 1 ? 1 : widget.travellerCount;
    return pax == 1 ? '/adult' : ' for $pax travellers';
  }

  /// Spells out what the total above the Book button covers, since on a round
  /// trip it is visibly larger than the fare card right above it.
  String get _tripTotalLabel {
    final legs = 1 + _additionalLegs.length;
    final pax = widget.travellerCount < 1 ? 1 : widget.travellerCount;
    final who = pax == 1 ? '1 traveller' : '$pax travellers';
    // if (legs <= 1) return 'Total · $who';
    if (legs <= 1) return 'Total';
    final trip =
        legs == 2 && (widget.tripType == 'RT' || widget.tripType == 'RS')
        ? 'round trip'
        : '$legs legs';
    return 'Total · $trip';
    return 'Total · $trip · $who';
  }

  String get _travellerLabel {
    final legs = 1 + _additionalLegs.length;
    final pax = widget.travellerCount < 1 ? 1 : widget.travellerCount;
    final who = pax == 1 ? 'for 1 traveller' : 'for $pax travellers';
    if (legs <= 1) return '$who';
    final trip =
        legs == 2 && (widget.tripType == 'RT' || widget.tripType == 'RS')
        ? 'round trip'
        : '$legs legs';
    return '$who';
  }

  /// The whole itinerary's price — every leg, every traveller — which is what
  /// the customer is about to pay. FlightInfo's NetAmount already spans all
  /// legs; DM/IM prefer GetSPricer's, because their per-leg FlightInfo can
  /// reflect only the active leg. Falls back to summing the picked legs so a
  /// total still shows before either call resolves.
  double _tripNetAmount(AkFlightInfoEntity data) {
    final isDmIm = widget.tripType == 'DM' || widget.tripType == 'IM';

    // DM/IM: sum per-leg gross fares so the total matches the fare
    // breakdown drawer and the fare family card's option.amount.
    if (isDmIm) {
      // For DM the pricer fans out per leg, so leg sums are accurate.
      // For IM the pricer only re-prices leg 1 — its single-trip
      // grossFare is NOT the whole-journey total, so skip it.
      if (widget.tripType == 'DM') {
        final pricerTrips = _pricerData?.trips ?? [];
        final flightTrips = data.trips;
        double legSum = 0;
        if (pricerTrips.isNotEmpty) {
          for (final trip in pricerTrips) {
            if (trip.journey.isNotEmpty) {
              legSum += trip.journey.first.grossFare;
            }
          }
        }
        if (legSum <= 0 && flightTrips.length > 1) {
          for (final trip in flightTrips) {
            if (trip.journey.isNotEmpty) {
              legSum += trip.journey.first.grossFare;
            }
          }
        }
        if (legSum > 0) return legSum;
      }
      // Sum the picked legs — data.grossAmount may reflect only the
      // active leg when FlightInfo/GetSPricer didn't fan out.
      return _selectedAmount +
          _additionalLegs.fold<double>(0, (sum, leg) => sum + leg.amount);
    }

    if (data.grossAmount > 0) return data.grossAmount;
    final pricerTotal = _pricerData?.grossAmount ?? 0;
    if (pricerTotal > 0) return pricerTotal;
    return _selectedAmount +
        _additionalLegs.fold<double>(0, (sum, leg) => sum + leg.amount);
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.resultIndex;
    _selectedAmount = widget.amount;
    _selectedNetAmount = widget.netAmount;
    _additionalLegs = List<FlightLegSelection>.of(widget.additionalLegs);

    _bloc = sl<AkFlightInfoBloc>();
    _smartPricerBloc = sl<AkSmartPricerBloc>();
    _pricerBloc = sl<AkGetSPricerBloc>();
    _fareRuleBloc = sl<AkFareRuleBloc>();
    _fareFamilyDetailsBloc = sl<AkFareFamilyDetailsBloc>();

    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );
    _expansionController.forward();

    _load();
    _loadFareRule();
    _initFareFamilyLabels();
    _loadFareFamilyDetails();
  }

  /// Seed fare labels immediately from the search data (FCType on each
  /// FareFamilyIndexEntity). FareFamilyDetails only adds baggage; it never
  /// returns labels, so we must not wait for it before showing names.
  void _initFareFamilyLabels() {
    final labels = <String, String>{};
    for (final opt in _fareOptions) {
      if (opt.label != null && opt.label!.isNotEmpty) {
        labels[opt.index] = opt.label!;
      }
    }
    if (labels.isNotEmpty) _fareFamilyLabels = labels;
  }

  void _loadFareFamilyDetails() {
    if (_fareOptions.isEmpty) return;
    final isDm = widget.tripType == 'DM';
    final isRt = widget.tripType == 'RT';
    final legTuis = isDm
        ? [
            widget.tui,
            for (final leg in _additionalLegs)
              if (leg.tui != null) leg.tui!,
          ]
        : <String>[];

    // RT: the backend requires EXACTLY 2 trips (outbound + return) in one call.
    // Sending only outbound fare options causes the backend to call SmartPricer
    // with a single trip — consuming the search TUI without caching the RT
    // pricing TUI/net_amount, causing "Net Amount Mismatch" at CreateItinerary.
    if (isRt && _additionalLegs.isNotEmpty) {
      final returnLeg = _additionalLegs.first;
      _fareFamilyDetailsBloc.add(
        LoadAkFareFamilyDetailsEvent(
          AkFareFamilyDetailsRequestEntity(
            tui: widget.tui,
            tuis: legTuis,
            tripType: widget.tripType,
            trips: [
              AkFareFamilyDetailsTripRequestEntity(
                index: _selectedIndex,
                amount: _selectedNetAmount,
                orderId: 1,
              ),
              AkFareFamilyDetailsTripRequestEntity(
                index: returnLeg.resultIndex,
                amount: returnLeg.netAmount,
                orderId: 2,
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Send ALL fare options so the backend returns baggage+rules for every
    // fare family, not just the currently selected one. The website does the
    // same via getOrFetchAkbarFareDetails(searchTui, allFareOptions, tripType).
    _fareFamilyDetailsBloc.add(
      LoadAkFareFamilyDetailsEvent(
        AkFareFamilyDetailsRequestEntity(
          tui: widget.tui,
          tuis: legTuis,
          tripType: widget.tripType,
          trips: _fareOptions
              .asMap()
              .entries
              .map(
                (e) => AkFareFamilyDetailsTripRequestEntity(
                  index: e.value.index,
                  amount: e.value.netAmount,
                  orderId: e.key + 1,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _loadFareRule() {
    // For DM: collect per-leg TUIs — leg 1 = widget.tui, others from additionalLegs.
    final isDm = widget.tripType == 'DM';
    final legTuis = isDm
        ? [
            widget.tui,
            for (final leg in _additionalLegs)
              if (leg.tui != null) leg.tui!,
          ]
        : <String>[];

    _fareRuleBloc.add(
      LoadAkFareRuleEvent(
        AkFareRuleRequestEntity(
          tui: widget.tui,
          tuis: legTuis,
          trips: [
            AkFareRuleTripRequestEntity(
              index: _selectedIndex,
              amount: _selectedNetAmount,
              orderId: 1,
            ),
            for (final leg in _additionalLegs)
              AkFareRuleTripRequestEntity(
                index: leg.resultIndex,
                amount: leg.netAmount,
                orderId: leg.orderId,
              ),
          ],
        ),
      ),
    );
  }

  void _load() {
    // For DM: each leg has its own search TUI — pass all so the backend
    // can look up each leg's index under the correct TUI.
    final isDm = widget.tripType == 'DM';
    final legTuis = isDm
        ? [
            widget.tui,
            for (final leg in _additionalLegs)
              if (leg.tui != null) leg.tui!,
          ]
        : <String>[];

    _bloc.add(
      LoadAkFlightInfoEvent(
        AkFlightInfoRequestEntity(
          tui: widget.tui,
          tripType: widget.tripType,
          tuis: legTuis,
          trips: [
            AkFlightInfoTripRequestEntity(
              index: _selectedIndex,
              amount: _selectedNetAmount,
              orderId: 1,
            ),
            for (final leg in _additionalLegs)
              AkFlightInfoTripRequestEntity(
                index: leg.resultIndex,
                amount: leg.netAmount,
                orderId: leg.orderId,
              ),
          ],
        ),
      ),
    );
  }

  void _loadSmartPricer(String searchTui, {bool preview = true}) {
    _smartPricerRequested = true;

    // For DM: collect per-leg TUIs stored in FlightLegSelection.tui.
    // For IM/RT the tuis list is empty and searchTui covers all legs.
    final isDm = widget.tripType == 'DM';
    final legTuis = isDm
        ? [
            searchTui, // first leg's TUI (= widget.tui)
            for (final leg in _additionalLegs)
              if (leg.tui != null) leg.tui!,
          ]
        : <String>[];

    _smartPricerBloc.add(
      LoadAkSmartPricerEvent(
        AkSmartPricerRequestEntity(
          searchTui: searchTui,
          tripType: widget.tripType,
          trips: [
            AkSmartPricerTripRequestEntity(
              index: _selectedIndex,
              amount: _selectedNetAmount,
              orderId: 1,
            ),
            for (final leg in _additionalLegs)
              AkSmartPricerTripRequestEntity(
                index: leg.resultIndex,
                // IM Trips[1..N] are zero-fare partner legs: Trips[0] carries
                // the whole package fare. Substituting the package total here
                // declares the journey at N× its price and GetSPricer fails
                // with 5071 "Pricing failed from provider".
                amount: leg.netAmount,
                orderId: leg.orderId,
              ),
          ],
          preview: preview,
          tuis: legTuis,
          adults: widget.adultCount > 0 ? widget.adultCount : 1,
          children: widget.childCount,
          infants: widget.infantCount,
        ),
      ),
    );
  }

  Future<void> _loadDmPricingPreview() async {
    _smartPricerRequested = true;
    final dmSessionId = widget.searchSessionId;
    if (dmSessionId == null || dmSessionId.isEmpty) {
      if (mounted) setState(() => _switchingFare = false);
      return;
    }

    final dio = sl<Dio>();
    final legs = [
      {'index': _selectedIndex, 'amount': _selectedNetAmount, 'order_id': 1},
      for (final leg in _additionalLegs)
        {
          'index': leg.resultIndex,
          'amount': leg.netAmount,
          'order_id': leg.orderId,
        },
    ];

    try {
      final spRes = await dio.post(
        Urls.multiCitySmartPricer,
        data: {'session_id': dmSessionId, 'legs': legs},
      );
      final spData = spRes.data as Map<String, dynamic>;
      if (spData['success'] != true) return;
      _sessionId = spData['session_id']?.toString() ?? dmSessionId;

      final gspRes = await dio.post(
        Urls.multiCityGetSPricer,
        data: {'session_id': _sessionId},
      );
      final gspData = gspRes.data as Map<String, dynamic>;
      if (gspData['success'] != true) return;

      _pricingTui =
          gspData['TUI']?.toString() ?? gspData['tui']?.toString() ?? '';
      _pricerData = AkGetSPricerModel.fromJson(gspData);
      _commitDone = true; // reuse this at Book Now time
      if (mounted) setState(() => _switchingFare = false);
    } catch (_) {
      // Silently ignore — _commitPricing() will retry at booking time.
      if (mounted) setState(() => _switchingFare = false);
    }
  }

  void _loadPricer(String smartPricerTui, {bool preview = true}) {
    _pricerRequested = true;
    _pricerBloc.add(
      LoadAkGetSPricerEvent(
        AkGetSPricerRequestEntity(tui: smartPricerTui, preview: preview),
      ),
    );
  }

  void _selectFare(FareFamilyIndexEntity option) {
    if (option.index == _activeLegIndex || _switchingFare) return;
    final tab = _activeLegTab;
    setState(() {
      if (tab == 0) {
        _selectedIndex = option.index;
        _selectedAmount = option.amount;
        _selectedNetAmount = option.netAmount;
        // IM: the new fare is a different package — its later legs are its
        // own partners, not the previous fare's.
        final partners = widget.imPartnerLegs[option.returnIdentifier];
        if (partners != null) {
          _additionalLegs = List<FlightLegSelection>.of(partners);
        }
      } else {
        // Same leg, different fare family: keep its orderId and TUI so the
        // pricing calls still address the right trip.
        final leg = _additionalLegs[tab - 1];
        _additionalLegs[tab - 1] = FlightLegSelection(
          orderId: leg.orderId,
          resultIndex: option.index,
          amount: option.amount,
          netAmount: option.netAmount,
          flight: leg.flight,
          tui: leg.tui,
        );
      }
      _switchingFare = true;
      _smartPricerRequested = false;
      _pricerRequested = false;
      _sessionId = null;
      _pricingTui = null;
      _pricerData = null;
      _commitDone = false;
      _fareChangeAccepted = false;
      // RT: disable Book Now until FlightInfo reloads for the new fare.
      if (widget.tripType == 'RT') _flightInfoLoaded = false;
    });
    _load();
    _loadFareRule();
    _initFareFamilyLabels();
    _loadFareFamilyDetails();
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _bloc.close();
    _smartPricerBloc.close();
    _pricerBloc.close();
    _fareRuleBloc.close();
    _fareFamilyDetailsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AkFlightInfoBloc>.value(value: _bloc),
        BlocProvider<AkSmartPricerBloc>.value(value: _smartPricerBloc),
        BlocProvider<AkGetSPricerBloc>.value(value: _pricerBloc),
        BlocProvider<AkFareRuleBloc>.value(value: _fareRuleBloc),
        BlocProvider<AkFareFamilyDetailsBloc>.value(
          value: _fareFamilyDetailsBloc,
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AkFlightInfoBloc, AkFlightInfoState>(
            listener: (context, state) {
              if (state is AkFlightInfoLoaded && !_smartPricerRequested) {
                // RT: do NOT call SmartPricer at all on init. Akbar allows only
                // ONE SmartPricer call per RT search TUI; calling it here (even
                // preview=true) consumes the TUI and makes FlightInfo/FareRule
                // fail for every subsequent popup on the same search. The single
                // allowed call is SmartPricer(preview=false) in _commitPricing()
                // when the user confirms the booking.
                if (widget.tripType == 'DM') {
                  // DM requires MultiCity/SmartPricer/ — standard SmartPricer
                  // returns error 300 for DM trip type.
                  _loadDmPricingPreview();
                } else if (widget.tripType == 'IM') {
                  _loadSmartPricer(widget.tui);
                } else {
                  // ON and RT: no SmartPricer on open at all.
                  //
                  // One SmartPricer — even preview=true — spends the search
                  // TUI, and every later FlightInfo on it comes back
                  // "No Record found" (502). RT already skipped it; ON did
                  // not, so opening a second fare from the same one-way
                  // search blew up on the error screen. The single allowed
                  // SmartPricer(preview:false) runs in _commitPricing() when
                  // the traveller actually books.
                  //
                  // FlightInfo is the end of the chain for both, so this is
                  // also the only place the fare-switch lock can be released.
                  setState(() {
                    _flightInfoLoaded = true;
                    _switchingFare = false;
                  });
                }
              } else if (state is AkFlightInfoFailed &&
                  !_smartPricerRequested) {
                // A failed reload must not leave the screen locked either —
                // the traveller needs to be able to pick a different fare.
                if (_switchingFare) setState(() => _switchingFare = false);
                // DM/IM: backend FlightInfo doesn't fan-out per-leg TUIs yet.
                final ft = widget.tripType;
                if (ft == 'DM') {
                  _loadDmPricingPreview();
                } else if (ft == 'IM') {
                  _loadSmartPricer(widget.tui);
                }
              }
            },
          ),
          BlocListener<AkSmartPricerBloc, AkSmartPricerState>(
            listener: (context, state) {
              if (state is AkSmartPricerLoaded) {
                _sessionId = state.data.sessionId;
                // _commitPricing() runs its own SmartPricer(preview:false) and
                // then awaits its own GetSPricer(preview:false). This listener
                // sees that same SmartPricer response, and firing a preview
                // GetSPricer here put two calls on one bloc and one TUI: the
                // preview answered first, _commitPricing()'s `firstWhere`
                // consumed it and declared the fare committed, while the real
                // preview:false call was still in flight. Akbar then rejected
                // CreateItinerary with "Net Amount Mismatch" because nothing
                // had actually been committed.
                if (!_pricerRequested && !_committing) {
                  _loadPricer(state.data.tui);
                }
              } else if (state is AkSmartPricerFailed) {
                if (_switchingFare) _switchingFare = false;
                // 1601 = Akbar session expired — show a specific message so the
                // user knows they need to re-search rather than retry.
                final body =
                    state.error.response?.data?.toString() ??
                    state.error.message ??
                    '';
                if (body.contains('1601') ||
                    body.toLowerCase().contains('no record found')) {
                  _showSessionExpiredDialog(context);
                }
              }
            },
          ),
          BlocListener<AkGetSPricerBloc, AkGetSPricerState>(
            listener: (context, state) {
              if (state is AkGetSPricerLoaded) {
                _pricingTui = state.data.tui;
                _pricerData = state.data;
                _switchingFare = false;
              } else if (state is AkGetSPricerFailed && _switchingFare) {
                _switchingFare = false;
              }
            },
          ),
          BlocListener<AkFareFamilyDetailsBloc, AkFareFamilyDetailsState>(
            listener: (context, state) {
              if (state is AkFareFamilyDetailsLoaded &&
                  state.data.options.isNotEmpty) {
                // FareFamilyDetails only provides baggage + fare_rule.
                // Labels (FCType) come from the search data via
                // _initFareFamilyLabels() and must not be overwritten here.
                final baggage = <String, Map<String, String?>>{};
                state.data.options.forEach((index, option) {
                  if (option.checkin != null || option.cabin != null) {
                    baggage[index] = {
                      'checkin': option.checkin,
                      'cabin': option.cabin,
                    };
                  }
                });
                if (baggage.isNotEmpty) {
                  setState(() => _fareFamilyBaggage = baggage);
                }
              }
            },
          ),
        ],
        // Own screen now (was a `showModalBottomSheet` — see `show()`), so
        // this is a plain Scaffold: a fixed header ("← Flight details & Fare
        // options", matching the Figma frame) above a scrolling body. Kept
        // the same FadeTransition it always had for the transition-in.
        child: Scaffold(
          backgroundColor: Colors.white,
          body: FadeTransition(
            opacity: _expansionAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  _pageHeader(context),
                  // Round trip / multi-city only — known synchronously from
                  // the constructor args, so the tab bar can sit fixed above
                  // the scrolling body (Figma) without waiting on FlightInfo.
                  if (_additionalLegs.isNotEmpty)
                    _legTabBar(context, _additionalLegs.length + 1),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        context.w(16),
                        context.h(8),
                        context.w(16),
                        context.h(20),
                      ),
                      child: _mainContent(context),
                    ),
                  ),
                  if (widget.tripType != 'ON') _fareBottomBar(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== PAGE HEADER (Figma: "← Flight details & Fare options") ====================
  Widget _pageHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.maybePop(context),
            child: Image.asset(
              'assets/NewIcons/arrowBack.png',
              width: context.w(24),
              height: context.h(24),
              color: _title900,
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Text(
              'Flight details & Fare options',
              style: TextStyle(
                color: _title900,
                fontSize: context.fs(16),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LEG TABS (Figma: ONWARD / RETURN / Trip N) ====================
  // Round trip / multi-city only — one-way never calls this (see `build()`'s
  // `_additionalLegs.isNotEmpty` guard), so it never affects one-way.
  Widget _legTabBar(BuildContext context, int totalLegs) {
    final isDm = widget.tripType == 'DM';
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < totalLegs; i++) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selectedLegTab = i),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(isDm ? 12 : 0),
                    vertical: context.h(10),
                  ),
                  constraints: isDm
                      ? null
                      : BoxConstraints(
                          minWidth:
                              MediaQuery.of(context).size.width / totalLegs,
                        ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedLegTab == i
                            ? AppColors.AppBlue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: isDm
                      ? _dmTabLabel(context, i)
                      : Text(
                          _legTabLabel(i, totalLegs),
                          style: TextStyle(
                            color: _selectedLegTab == i
                                ? AppColors.AppBlue
                                : AppColors.subhead,
                            fontSize: context.fs(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (isDm && i < totalLegs - 1)
                Container(
                  width: 1,
                  height: context.h(36),
                  color: const Color(0xFFE5E7EB),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Two-line tab for DM legs: "Trip N" header + "FROM → TO" route sub-label.
  Widget _dmTabLabel(BuildContext context, int index) {
    final isActive = _selectedLegTab == index;
    // Leg 0 uses widget.fromCode/toCode; subsequent legs use additionalLegs.
    final String from;
    final String to;
    if (index == 0) {
      from = widget.fromCode;
      to = widget.toCode;
    } else {
      final leg = _additionalLegs[index - 1];
      from = leg.flight.origin ?? '';
      to = leg.flight.destination ?? '';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Trip ${index + 1}',
          style: TextStyle(
            color: isActive ? AppColors.AppBlue : AppColors.subhead,
            fontSize: context.fs(12),
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$from → $to',
          style: TextStyle(
            color: isActive ? AppColors.AppBlue : AppColors.subhead,
            fontSize: context.fs(10),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _legTabLabel(int index, int totalLegs) {
    // IM is a multi-city package — always use "Leg N" labels.
    if (widget.tripType == 'IM') return 'Leg ${index + 1}';
    if (totalLegs == 2) return index == 0 ? 'ONWARD' : 'RETURN';
    return 'FLIGHT ${index + 1}';
  }

  // ==================== IMMEDIATE PLACEHOLDER (before FlightInfo resolves) ====================
  /// Shown the instant the sheet opens, before AkFlightInfo/GetSPricer have
  /// answered — built entirely from what the tapped search-result card
  /// already gave this widget (widget.fromCode/toCode/departureTime/
  /// arrivalTime/duration/price), so the user sees their flight immediately
  /// instead of a bare spinner. Only the extra detail that genuinely requires
  /// the API (stops/terminals/baggage/amenities/fare rules/Book Now) waits.
  Widget _placeholderContent(BuildContext context) {
    return Column(
      children: [
        _flightRouteCardFromWidget(context),
        SizedBox(height: context.h(16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: context.w(14),
              height: context.w(14),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xff3B82F6),
              ),
            ),
            SizedBox(width: context.w(8)),
            Text(
              'Fetching baggage, seats & fare details…',
              style: TextStyle(
                color: const Color(0xff64748B),
                fontSize: context.fs(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _flightRouteCardFromWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: _stroke, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // widget.departureTime/arrivalTime are already formatted "HH:mm"
          // strings by the caller — NOT raw ISO timestamps — so they're used
          // as-is here, unlike the loaded route card below which parses real
          // API data with _formatTime.
          _routeGradientHeader(
            context,
            fromCode: widget.fromCode,
            fromName: '',
            toCode: widget.toCode,
            toName: '',
          ),
          _routeAirlineRow(
            context,
            airlineCode: widget.airlineCode,
            airlineName: widget.airlineName,
            flightNo: widget.flightNumber,
            aircraft: '',
            cabin: '',
          ),
          Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: Row(
              children: [
                // No calendar-date chip here — unlike the loaded route card
                // below, the raw ISO departure timestamp was already reduced
                // to just "HH:mm" by the caller before reaching this widget,
                // so there's no real date to show yet. Only genuinely-known
                // fields are shown until FlightInfo resolves.
                _infoChip(
                  context,
                  Icons.schedule,
                  widget.duration,
                  size: context.w(12),
                ),
                SizedBox(width: context.w(8)),
                _infoChip(
                  context,
                  Icons.sell_outlined,
                  widget.price,
                  size: context.w(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FLIGHT ROUTE CARD ====================
  Widget _flightRouteCard(
    BuildContext context,
    AkFlightInfoEntity data, [
    AkGetSPricerEntity? pricerData,
  ]) {
    final journey = data.trips.isNotEmpty && data.trips.first.journey.isNotEmpty
        ? data.trips.first.journey.first
        : null;

    if (journey == null || journey.segments.isEmpty) {
      return _emptyState(context);
    }

    final segments = journey.segments;
    final firstFlight = segments.first.flight;
    final lastFlight = segments.last.flight;
    final airlineCode = _airlineCodeOf(firstFlight);
    final airlineName = _marketingSegment(
      firstFlight.airline,
      fallback: widget.airlineName,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: _stroke, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _routeGradientHeader(
            context,
            fromCode: firstFlight.departureCode,
            fromName: _shortCityName(firstFlight.depAirportName),
            toCode: lastFlight.arrivalCode,
            toName: _shortCityName(lastFlight.arrAirportName),
          ),
          _routeAirlineRow(
            context,
            airlineCode: airlineCode,
            airlineName: airlineName,
            flightNo: '$airlineCode${firstFlight.flightNo}',
            aircraft: firstFlight.aircraft.isNotEmpty
                ? firstFlight.aircraft
                : firstFlight.equipmentType,
            cabin: firstFlight.cabin,
          ),
          Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _timeLocation(
                        context,
                        time: _formatTime(firstFlight.departureTime),
                        code: '',
                        name: _formatDate(firstFlight.departureTime),
                        extra:
                            '${firstFlight.departureCode}${firstFlight.departureTerminal.isNotEmpty ? ', Terminal ${firstFlight.departureTerminal}' : ''}',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _flightPathWithStops(
                        context,
                        segments,
                        duration: _cleanDuration(
                          journey.duration,
                          depTime: firstFlight.departureTime,
                          arrTime: lastFlight.arrivalTime,
                        ),
                        journeyStops: journey.stops,
                      ),
                    ),
                    Expanded(
                      child: _timeLocation(
                        context,
                        time: _formatTime(lastFlight.arrivalTime),
                        code: '',
                        name: _formatDate(lastFlight.arrivalTime),
                        extra:
                            '${lastFlight.arrivalCode}${lastFlight.arrivalTerminal.isNotEmpty ? ', Terminal ${lastFlight.arrivalTerminal}' : ''}',
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(24)),
                _routeDetailsFooter(
                  context,
                  expanded: _flightDetailsExpanded,
                  onToggle: () => setState(
                    () => _flightDetailsExpanded = !_flightDetailsExpanded,
                  ),
                ),
                if (_flightDetailsExpanded)
                  _expandedFlightDetails(
                    context,
                    segments,
                    journey,
                    pricerData,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ROUTE GRADIENT HEADER (Figma: DEL ✈ DXB) ====================
  Widget _routeGradientHeader(
    BuildContext context, {
    required String fromCode,
    required String fromName,
    required String toCode,
    required String toName,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(24)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.AppBlue, Color(0xFFFFFFFF)],
          stops: [0.0, 1.0], // Simple two-color gradient
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fromCode,
                style: TextStyle(
                  color: _title900,
                  fontSize: context.fs(24),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.75,
                ),
              ),
              if (fromName.isNotEmpty)
                Text(
                  fromName,
                  style: TextStyle(
                    color: _title900,
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Row(
                children: [
                  Expanded(child: _dashedLine(context, color: Colors.white)),
                  Container(
                    width: context.w(35),
                    height: context.w(35),
                    margin: EdgeInsets.symmetric(horizontal: context.w(4)),
                    decoration: BoxDecoration(
                      color: AppColors.AppBlue.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          padding: EdgeInsets.all(context.w(12)),
                          child: Image.asset(
                            'assets/NewIcons/flight2.png',
                            color: Color(0xFFF2F2F7),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _dashedLine(context, color: Colors.white)),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                toCode,
                style: TextStyle(
                  color: _title900,
                  fontSize: context.fs(24),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.75,
                ),
              ),
              if (toName.isNotEmpty)
                Text(
                  toName,
                  style: TextStyle(
                    color: _title900,
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Evenly-spaced dashed line filling the available width — matches
  /// Figma's `border-dashed` divider either side of the route icon.
  Widget _dashedLine(BuildContext context, {required Color color}) {
    const dashWidth = 4.0;
    const dashGap = 3.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / (dashWidth + dashGap))
            .floor()
            .clamp(1, 1000);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(width: dashWidth, height: 1, color: color),
          ),
        );
      },
    );
  }

  // ==================== ROUTE AIRLINE ROW (Figma: IndiGo 6E 1461 / Airbus A321 · ECONOMY) ====================
  Widget _routeAirlineRow(
    BuildContext context, {
    required String airlineCode,
    required String airlineName,
    required String flightNo,
    required String aircraft,
    required String cabin,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(16),
        context.w(16),
        context.h(17),
      ),
      child: Row(
        children: [
          // The Figma mock's navy square happens to be IndiGo's own logo
          // mark (that example flight is IndiGo) — not a generic icon, so
          // showing the real per-flight airline logo here is correct for
          // every other airline too.
          _airlineLogo(context, airlineCode, airlineName, size: context.w(32)),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        airlineName,
                        style: TextStyle(
                          color: _title900,
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (flightNo.isNotEmpty) ...[
                      SizedBox(width: context.w(4)),
                      Text(
                        flightNo,
                        style: TextStyle(
                          color: AppColors.subhead,
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (aircraft.isNotEmpty)
                  Text(
                    aircraft,
                    style: TextStyle(
                      color: AppColors.subhead,
                      fontSize: context.fs(12),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          if (cabin.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                color: AppColors.AppBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(context.r(9999)),
              ),
              child: Text(
                _getFullCabinName(cabin).toUpperCase(),
                // cabin.toUpperCase(),
                style: TextStyle(
                  color: AppColors.AppBlue,
                  fontSize: context.fs(12),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== ROUTE DETAILS FOOTER (Figma: baggage/seat/meal icons + "View flight details") ====================
  Widget _routeDetailsFooter(
    BuildContext context, {
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: EdgeInsets.only(top: context.h(17)),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/Newimage/bag.png',
                width: context.w(16),
                height: context.w(16),
              ),
              SizedBox(width: context.w(12)),
              Image.asset(
                'assets/Newimage/sofa.png',
                width: context.w(16),
                height: context.w(16),
              ),
              SizedBox(width: context.w(12)),
              Image.asset(
                'assets/Newimage/fork.png',
                width: context.w(16),
                height: context.w(16),
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: [
                Text(
                  expanded ? 'Hide flight details' : 'View flight details',
                  style: TextStyle(
                    color: AppColors.AppBlue,
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: context.w(4)),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: context.w(14),
                  color: AppColors.AppBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extra detail revealed by "View flight details". Figma shows two
  /// different things here depending on the journey:
  /// - With a stop ("aIR CLICK Business with stop"): the total-duration row
  ///   above stays as-is (collapsed state always shows the total time), and
  ///   expanding distributes it into one airline-row + times-row block per
  ///   real segment, each with its own actual times/terminals/duration —
  ///   not the journey total repeated.
  /// - Non-stop: unchanged from whatever this already showed.
  Widget _expandedFlightDetails(
    BuildContext context,
    List<AkFlightInfoSegmentEntity> segments,
    AkFlightInfoJourneyEntity journey,
    AkGetSPricerEntity? pricerData,
  ) {
    if (segments.length > 1) {
      return Column(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) ...[
              SizedBox(height: context.h(12)),
              _layoverCard(context, segments[i - 1], segments[i]),
              SizedBox(height: context.h(12)),
            ],
            _segmentDetailRow(context, segments[i]),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// Layover banner shown between two connecting segments in the expanded
  /// flight details view (tap "view flight details").
  Widget _layoverCard(
    BuildContext context,
    AkFlightInfoSegmentEntity prev,
    AkFlightInfoSegmentEntity next,
  ) {
    final arrCode = prev.flight.arrivalCode;
    final arrName = prev.flight.arrAirportName;
    String layoverText = '';
    try {
      final arr = prev.flight.arrivalTime;
      final dep = next.flight.departureTime;
      if (arr.isNotEmpty && dep.isNotEmpty) {
        final diff = DateTime.parse(dep).difference(DateTime.parse(arr));
        if (diff.inMinutes > 0) {
          final h = diff.inHours;
          final m = diff.inMinutes % 60;
          layoverText = h > 0
              ? '${h}h ${m.toString().padLeft(2, '0')}m'
              : '${m}m';
        }
      }
    } catch (_) {}

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: const Color(0xFFFFD580), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_filled_rounded,
            size: context.w(14),
            color: const Color(0xffE07B00),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: context.fs(10),
                  color: const Color(0xff92400E),
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: 'Layover at '),
                  TextSpan(
                    text: arrCode,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (arrName.isNotEmpty) TextSpan(text: ' · $arrName'),
                  if (layoverText.isNotEmpty)
                    TextSpan(
                      text: '  $layoverText',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xffE07B00),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One connecting segment's own airline row + times row (Figma: "aIR
  /// CLICK Business with stop") — real per-segment departure/arrival/
  /// terminal/duration, not the journey total repeated per segment.
  Widget _segmentDetailRow(
    BuildContext context,
    AkFlightInfoSegmentEntity segment,
  ) {
    final f = segment.flight;
    final airlineCode = _airlineCodeOf(f);
    final airlineName = _marketingSegment(f.airline, fallback: airlineCode);

    return Column(
      children: [
        _routeAirlineRow(
          context,
          airlineCode: airlineCode,
          airlineName: airlineName,
          flightNo: '$airlineCode${f.flightNo}',
          aircraft: f.aircraft.isNotEmpty ? f.aircraft : f.equipmentType,
          cabin: f.cabin,
        ),
        Padding(
          padding: EdgeInsets.only(top: context.h(16)),
          child: Row(
            children: [
              Expanded(
                child: _timeLocation(
                  context,
                  time: _formatTime(f.departureTime),
                  code: '',
                  name: _formatDate(f.departureTime),
                  extra:
                      '${f.departureCode}${f.departureTerminal.isNotEmpty ? ', Terminal ${f.departureTerminal}' : ''}',
                ),
              ),
              Expanded(
                flex: 2,
                child: _segmentDurationLine(
                  context,
                  duration: _cleanDuration(
                    f.duration,
                    depTime: f.departureTime,
                    arrTime: f.arrivalTime,
                  ),
                ),
              ),
              Expanded(
                child: _timeLocation(
                  context,
                  time: _formatTime(f.arrivalTime),
                  code: '',
                  name: _formatDate(f.arrivalTime),
                  extra:
                      '${f.arrivalCode}${f.arrivalTerminal.isNotEmpty ? ', Terminal ${f.arrivalTerminal}' : ''}',
                  alignRight: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bare icon + duration + dotted line, no stop-count label underneath —
  /// used per-segment, where "NON STOP" / "N STOPS" doesn't apply (that's
  /// the whole journey's property, shown once above by
  /// [_flightPathWithStops]).
  Widget _segmentDurationLine(
    BuildContext context, {
    required String duration,
  }) {
    Widget dot() => Container(
      width: context.w(8),
      height: context.w(8),
      decoration: const BoxDecoration(
        color: AppColors.AppBlue,
        shape: BoxShape.circle,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: context.w(12), color: AppColors.subhead),
            SizedBox(width: context.w(4)),
            Text(
              duration,
              style: TextStyle(
                color: AppColors.subhead,
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(4)),
        Row(
          children: [
            dot(),
            Expanded(child: Container(height: 1, color: AppColors.AppBlue)),
            dot(),
          ],
        ),
      ],
    );
  }

  Widget _timeLocation(
    BuildContext context, {
    required String time,
    required String code,
    required String name,
    String extra = '',
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            color: const Color(0xff0F172A),
            fontSize: context.fs(18),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (code.isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            code,
            style: TextStyle(
              color: const Color(0xff475569),
              fontSize: context.fs(13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (name.isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            name,
            style: TextStyle(
              color: AppColors.subhead,
              fontSize: context.fs(10),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (extra.isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            extra,
            style: TextStyle(
              color: AppColors.subhead,
              fontSize: context.fs(10),
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _flightPathWithStops(
    BuildContext context,
    List<AkFlightInfoSegmentEntity> segments, {
    required String duration,
    int? journeyStops,
  }) {
    final stopsFromSegments = segments.length - 1;
    final stopCount = (journeyStops != null && journeyStops > stopsFromSegments)
        ? journeyStops
        : stopsFromSegments;
    final isDirect = stopCount == 0;
    final stopLabel = isDirect
        ? 'NON STOP'
        : '$stopCount STOP${stopCount > 1 ? 'S' : ''}';

    Widget dot() => Container(
      width: context.w(8),
      height: context.w(8),
      decoration: const BoxDecoration(
        color: AppColors.AppBlue,
        shape: BoxShape.circle,
      ),
    );

    return Column(
      children: [
        // Icon + duration, above the line (Figma).
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: context.w(12), color: AppColors.subhead),
            SizedBox(width: context.w(4)),
            Text(
              duration,
              style: TextStyle(
                color: AppColors.subhead,
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(4)),
        Row(
          children: [
            dot(),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  // `colors` and `stops` must be the same length (Flutter
                  // asserts this) — the 3-stop gradient needs 3 colors, not 2,
                  // or every connecting (non-direct) flight throws here.
                  gradient: LinearGradient(
                    colors: isDirect
                        ? const [AppColors.AppBlue, AppColors.AppBlue]
                        : const [
                            AppColors.AppBlue,
                            AppColors.AppBlue,
                            Color(0xff94A3B8),
                          ],
                    stops: isDirect ? const [0, 1] : const [0, 0.7, 1],
                  ),
                ),
              ),
            ),
            if (!isDirect) ...[
              Container(
                width: context.w(18),
                height: context.w(18),
                decoration: BoxDecoration(
                  color: const Color(0xffF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff94A3B8), width: 1),
                ),
                child: Center(
                  child: Text(
                    '$stopCount',
                    style: TextStyle(
                      color: const Color(0xff475569),
                      fontSize: context.fs(9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff94A3B8), AppColors.AppBlue],
                    ),
                  ),
                ),
              ),
            ],
            dot(),
          ],
        ),
        SizedBox(height: context.h(4)),
        Text(
          stopLabel,
          style: TextStyle(
            color: AppColors.subhead,
            fontSize: context.fs(10),
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        if (!isDirect && _viaAirportsOf(segments).isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            'via ${_viaAirportsOf(segments).join(', ')}',
            style: TextStyle(
              color: AppColors.subhead,
              fontSize: context.fs(9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ==================== SELECT FARE OPTIONS (Figma) ====================
  Widget _fareSelector(BuildContext context) {
    final sorted = [..._fareOptions]
      ..sort((a, b) => a.amount.compareTo(b.amount));
    // Only ever show up to 3 fare cards — Saver (cheapest) / Standard
    // (middle) / Flexi (priciest) — instead of one card per raw fare
    // option, which could be 5+ and left several cards all labelled
    // "Standard" (see _getFareLabel).
    final displayed = _capFareOptions(sorted);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Fare options',
            style: TextStyle(
              color: _title900,
              fontSize: context.fs(16),
              fontWeight: FontWeight.w600,
            ),
          ),
          // SizedBox(height: context.h(16)),
          // Horizontally scrollable row of equal-height, equal-width cards.
          // LayoutBuilder gives us the available width so each card is a
          // responsive fraction of the screen rather than a hardcoded pixel value.
          // LayoutBuilder(
          //   builder: (context, constraints) {
          //     // Each card is ~40 % of available width, min 130 px, max 180 px.
          //     // This keeps 2–3 cards visible at once and still allows scrolling
          //     // when there are more families.
          //     final cardWidth = (constraints.maxWidth * 0.40).clamp(130.0, 180.0);
          //     const gap = 12.0;
          //     return SingleChildScrollView(
          //       scrollDirection: Axis.horizontal,
          //       physics: const BouncingScrollPhysics(),
          //       clipBehavior: Clip.none,
          //       child: IntrinsicHeight(
          //         child: Row(
          //           crossAxisAlignment: CrossAxisAlignment.stretch,
          //           children: [
          //             for (var i = 0; i < displayed.length; i++) ...[
          //               if (i > 0) SizedBox(width: gap),
          //               SizedBox(
          //                 width: cardWidth,
          //                 child: _fareCard(
          //                   context,
          //                   displayed[i],
          //                   i,
          //                   displayed.length,
          //                 ),
          //               ),
          //             ],
          //           ],
          //         ),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  /// Reduces a price-sorted fare list down to at most 3 entries: the
  /// cheapest, the priciest, and one representative in between — so
  /// [_getFareLabel]'s Saver/Standard/Flexi labels each show at most once.
  /// Lists of 3 or fewer are left untouched (still their real fares).
  List<FareFamilyIndexEntity> _capFareOptions(
    List<FareFamilyIndexEntity> sorted,
  ) {
    if (sorted.length <= 3) return sorted;
    final middle = sorted[sorted.length ~/ 2];
    return [sorted.first, middle, sorted.last];
  }

  Widget _fareCard(
    BuildContext context,
    FareFamilyIndexEntity option,
    int rank,
    int total,
  ) {
    final selected = option.index == _activeLegIndex;
    final bool canSelect = !selected && !_switchingFare;
    final bag = _fareFamilyBaggage[option.index];
    final checkin = bag?['checkin'];
    final cabin = bag?['cabin'];
    final hasBaggage = checkin != null || cabin != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: canSelect ? () => _selectFare(option) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            // Width is set by the parent SizedBox in _fareSelector so all
            // cards are the same responsive width.
            // Height stretches to match the tallest sibling (IntrinsicHeight).
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(10),
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(context.r(12)),
              border: Border.all(
                color: selected ? AppColors.AppBlue : _stroke,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getFareLabel(option, rank, total),
                  style: TextStyle(
                    color: selected ? AppColors.AppBlue : _title900,
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.h(4)),
                Text(
                  context.money(option.amount),
                  style: TextStyle(
                    color: selected ? AppColors.AppBlue : AppColors.subhead,
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasBaggage) ...[
                  SizedBox(height: context.h(5)),
                  Row(
                    children: [
                      Icon(
                        Icons.luggage_rounded,
                        size: context.fs(11),
                        color: selected
                            ? AppColors.AppBlue.withValues(alpha: 0.75)
                            : const Color(0xff64748B),
                      ),
                      SizedBox(width: context.w(3)),
                      Flexible(
                        child: Text(
                          [
                            if (checkin != null) checkin,
                            if (cabin != null) '$cabin cabin',
                          ].join(' + '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(10),
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? AppColors.AppBlue.withValues(alpha: 0.75)
                                : const Color(0xff64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        // Checkmark badge - shifted slightly above
        if (selected)
          Positioned(
            right: -context.w(2),
            top: -context.h(8), // Shifted further up (was -2, now -8)
            child: Container(
              width: context.w(20),
              height: context.w(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.AppBlue,
                size: context.w(20),
              ),
            ),
          ),
        // Loading indicator when switching
        if (_switchingFare && selected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
              child: Center(
                child: SizedBox(
                  width: context.w(18),
                  height: context.w(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.AppBlue,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getFareLabel(FareFamilyIndexEntity option, int rank, int total) {
    // Prefer the name returned by the FareFamilyDetails API when available.
    final apiLabel = _fareFamilyLabels[option.index];
    if (apiLabel != null && apiLabel.isNotEmpty) {
      return _toTitleCase(apiLabel);
    }
    // Fallback: rank-based labels until/if the API doesn't return names.
    if (rank == 0) return 'Saver';
    if (rank == total - 1) return 'Flexi';
    return 'Standard';
  }

  String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  // ==================== MAIN CONTENT ====================
  Widget _mainContent(BuildContext context) {
    return BlocBuilder<AkFlightInfoBloc, AkFlightInfoState>(
      builder: (context, flightInfoState) {
        final ft = widget.tripType;
        final flightInfoFailed = flightInfoState is AkFlightInfoFailed;
        final skipFlightInfo = flightInfoFailed && (ft == 'DM' || ft == 'IM');

        // Cache good data so we can keep the screen stable during fare switches.
        if (flightInfoState is AkFlightInfoLoaded) {
          _cachedFlightInfo = flightInfoState.data;
        }

        // During a fare switch: FlightInfo re-enters Loading, but we have
        // cached data — keep showing the loaded layout with shimmer in the
        // updating sections instead of dropping to _placeholderContent.
        if (_switchingFare && _cachedFlightInfo != null) {
          return _loadedContent(
            context,
            _cachedFlightInfo!,
            _cachedPricerData,
            true,
          );
        }

        if (flightInfoFailed && !skipFlightInfo) {
          return _errorState(
            context,
            _flightInfoErrorText(flightInfoState.error),
          );
        }
        if (flightInfoState is AkFlightInfoLoaded || skipFlightInfo) {
          return BlocBuilder<AkGetSPricerBloc, AkGetSPricerState>(
            builder: (context, pricerState) {
              if (pricerState is AkGetSPricerLoaded) {
                _cachedPricerData = pricerState.data;
                if (flightInfoState is AkFlightInfoLoaded) {
                  final merged = _mergeWithPricer(
                    flightInfoState.data,
                    pricerState.data,
                  );
                  return _loadedContent(context, merged, pricerState.data);
                }
                final pricerOnly = _mergeWithPricer(
                  _emptyFlightInfo(),
                  pricerState.data,
                );
                return _loadedContent(context, pricerOnly, pricerState.data);
              }
              if (flightInfoState is AkFlightInfoLoaded) {
                return _loadedContent(context, flightInfoState.data);
              }
              final ft = widget.tripType;
              if ((ft == 'DM' || ft == 'IM') &&
                  (pricerState is AkGetSPricerFailed ||
                      pricerState is AkGetSPricerInitial)) {
                return _dmImWidgetContent(context);
              }
              return _placeholderContent(context);
            },
          );
        }
        return _placeholderContent(context);
      },
    );
  }

  /// Fallback content for DM/IM when FlightInfo failed and GetSPricer has
  /// not yet loaded (or also failed). Uses widget-data fields so the route
  /// card and Book Now button render immediately while the backend catches up.
  Widget _dmImWidgetContent(BuildContext context) {
    // Determine which leg to display based on the active tab.
    final tabIndex = _selectedLegTab;
    final bool isAdditionalLeg =
        tabIndex > 0 && tabIndex - 1 < _additionalLegs.length;
    final FlightLegSelection? activeLeg = isAdditionalLeg
        ? _additionalLegs[tabIndex - 1]
        : null;

    final String legFrom = activeLeg?.flight.origin ?? widget.fromCode;
    final String legTo = activeLeg?.flight.destination ?? widget.toCode;
    final String legAirline =
        activeLeg?.flight.airlineName ?? widget.airlineName;
    final String legAirlineCode =
        activeLeg?.flight.airlineCode ?? widget.airlineCode;
    final String legFlightNo =
        activeLeg?.flight.flightNumber ?? widget.flightNumber;
    final String legDep =
        activeLeg?.flight.departureTime ?? widget.departureTime;
    final String legArr = activeLeg?.flight.arrivalTime ?? widget.arrivalTime;
    final String legDuration = activeLeg?.flight.duration ?? widget.duration;
    final double legAmount = activeLeg?.amount ?? widget.amount;
    final int legStops = activeLeg?.flight.stops ?? 0;

    return Column(
      children: [
        _dmLegRouteCard(
          context,
          fromCode: legFrom,
          toCode: legTo,
          airlineCode: legAirlineCode,
          airlineName: legAirline,
          flightNo: legFlightNo,
          departureTime: legDep,
          arrivalTime: legArr,
          duration: legDuration,
          stops: legStops,
        ),
        SizedBox(height: context.h(20)),
        _fareFamilyDetailCard(context, null, false),
        // SizedBox(height: context.h(20)),
        // _priceDropProtectionToggle(context),
        SizedBox(height: context.h(30)),
        // Build a minimal entity + journey from the active leg's data so
        // _bookButton / _handleBookNow can construct a FlightRouteSegment.
        Builder(
          builder: (ctx) {
            final minJourney = AkFlightInfoJourneyEntity(
              provider: '',
              stops: 0,
              orderId: 1,
              grossFare: legAmount,
              netFare: legAmount,
              duration: legDuration,
              promo: '',
              fareType: widget.tripType,
              segments: [
                AkFlightInfoSegmentEntity(
                  flight: AkFlightInfoFlightEntity(
                    fuid: 0,
                    vac: '',
                    mac: '',
                    oac: '',
                    fbc: '',
                    airline: legAirline,
                    flightNo: legFlightNo,
                    departureTime: legDep,
                    arrivalTime: legArr,
                    fareClass: '',
                    departureCode: legFrom,
                    arrivalCode: legTo,
                    departureTerminal: '',
                    arrivalTerminal: '',
                    depAirportName: legFrom,
                    arrAirportName: legTo,
                    equipmentType: '',
                    aircraft: '',
                    rbd: '',
                    cabin: '',
                    refundable: 'N',
                    seats: 0,
                    duration: legDuration,
                  ),
                  fare: const AkFlightInfoFareEntity(
                    grossFare: 0,
                    netFare: 0,
                    totalBaseFare: 0,
                    totalTax: 0,
                    totalServiceTax: 0,
                    totalTransactionFee: 0,
                    totalCommission: 0,
                  ),
                ),
              ],
            );
            final minEntity = AkFlightInfoEntity(
              success: true,
              sessionId: _sessionId ?? '',
              tui: widget.tui,
              from: legFrom,
              to: legTo,
              fromName: legFrom,
              toName: legTo,
              onwardDate: '',
              adultCount: widget.adultCount,
              childCount: widget.childCount,
              infantCount: widget.infantCount,
              netAmount: legAmount,
              grossAmount: legAmount,
              fareType: widget.tripType,
              hold: false,
              trips: [
                AkFlightInfoTripEntity(journey: [minJourney]),
              ],
            );
            return _bookButton(ctx, minEntity, minJourney, false, false);
          },
        ),
      ],
    );
  }

  /// Route card for a single DM leg using explicit field values (not widget.*).
  Widget _dmLegRouteCard(
    BuildContext context, {
    required String fromCode,
    required String toCode,
    required String airlineCode,
    required String airlineName,
    required String flightNo,
    required String departureTime,
    required String arrivalTime,
    required String duration,
    int stops = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: _stroke, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _routeGradientHeader(
            context,
            fromCode: fromCode,
            fromName: '',
            toCode: toCode,
            toName: '',
          ),
          _routeAirlineRow(
            context,
            airlineCode: airlineCode,
            airlineName: airlineName,
            flightNo: flightNo,
            aircraft: '',
            cabin: '',
          ),
          Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: Row(
              children: [
                _infoChip(
                  context,
                  Icons.schedule,
                  duration,
                  size: context.w(12),
                ),
                SizedBox(width: context.w(8)),
                _infoChip(
                  context,
                  Icons.circle_outlined,
                  stops == 0
                      ? 'Non Stop'
                      : '$stops Stop${stops > 1 ? 's' : ''}',
                  size: context.w(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A completely empty AkFlightInfoEntity used as a placeholder when
  /// FlightInfo is skipped (DM/IM without backend fan-out support).
  /// _mergeWithPricer overwrites every meaningful field from GetSPricer.
  AkFlightInfoEntity _emptyFlightInfo() {
    return const AkFlightInfoEntity(
      success: false,
      sessionId: '',
      tui: '',
      from: '',
      to: '',
      fromName: '',
      toName: '',
      onwardDate: '',
      adultCount: 0,
      childCount: 0,
      infantCount: 0,
      netAmount: 0,
      grossAmount: 0,
      fareType: '',
      hold: false,
      trips: [],
    );
  }

  /// Picks the correct route card for the active tab.
  ///
  /// For one-way: always [_flightRouteCard] from FlightInfo data.
  /// For RT/IM: [_legRouteCard] for each trip in [legJourneys].
  /// For DM: FlightInfo may only return trip 1 — for tabs beyond what
  /// FlightInfo resolved, fall back to a widget-data card so the user can
  /// still see the other legs' basic info.
  Widget _activeRouteCard(
    BuildContext context,
    List<AkFlightInfoJourneyEntity> legJourneys,
    AkFlightInfoEntity data,
    AkGetSPricerEntity? pricerData,
  ) {
    final totalLegs = 1 + _additionalLegs.length;
    final tab = _selectedLegTab.clamp(0, totalLegs - 1);

    if (legJourneys.length <= 1 && totalLegs == 1) {
      // Plain one-way.
      return _flightRouteCard(context, data, pricerData);
    }

    if (tab < legJourneys.length) {
      // FlightInfo returned data for this leg.
      return _legRouteCard(context, journey: legJourneys[tab]);
    }

    // DM leg beyond what FlightInfo returned — synthesise a journey from
    // search data so _legRouteCard renders it in the same rich card style.
    if (tab == 0) {
      return _legRouteCard(
        context,
        journey: _journeyFromWidgetData(
          fromCode: widget.fromCode,
          toCode: widget.toCode,
          airlineCode: widget.airlineCode,
          airlineName: widget.airlineName,
          flightNo: widget.flightNumber,
          departureTime: widget.departureTime,
          arrivalTime: widget.arrivalTime,
          duration: widget.duration,
          stops: 0,
          refundable: 'N',
          cabin: '',
        ),
      );
    }
    final leg = _additionalLegs[tab - 1];
    final f = leg.flight;
    return _legRouteCard(
      context,
      journey: _journeyFromWidgetData(
        fromCode: f.origin ?? '',
        toCode: f.destination ?? '',
        fromName: f.originName ?? '',
        toName: f.destinationName ?? '',
        airlineCode: f.airlineCode ?? '',
        airlineName: f.airlineName ?? '',
        flightNo: f.flightNumber ?? '',
        departureTime: f.departureTime ?? '',
        arrivalTime: f.arrivalTime ?? '',
        duration: _durationToMinutesStr(f.duration ?? ''),
        stops: f.stops ?? 0,
        refundable: (f.refundable ?? false) ? 'Y' : 'N',
        cabin: f.cabinClass ?? '',
      ),
    );
  }

  /// Builds a minimal [AkFlightInfoJourneyEntity] from raw field values so
  /// [_legRouteCard] can render legs where FlightInfo data is unavailable.
  AkFlightInfoJourneyEntity _journeyFromWidgetData({
    required String fromCode,
    required String toCode,
    String fromName = '',
    String toName = '',
    required String airlineCode,
    required String airlineName,
    required String flightNo,
    required String departureTime,
    required String arrivalTime,
    required String duration,
    required int stops,
    required String refundable,
    required String cabin,
  }) {
    final flight = AkFlightInfoFlightEntity(
      fuid: 0,
      vac: '',
      mac: airlineCode,
      oac: airlineCode,
      fbc: '',
      airline: airlineName,
      flightNo: flightNo,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      fareClass: '',
      departureCode: fromCode,
      arrivalCode: toCode,
      departureTerminal: '',
      arrivalTerminal: '',
      depAirportName: fromName.isNotEmpty ? fromName : fromCode,
      arrAirportName: toName.isNotEmpty ? toName : toCode,
      equipmentType: '',
      aircraft: '',
      rbd: '',
      cabin: cabin,
      refundable: refundable,
      seats: 0,
      duration: duration,
    );
    const fare = AkFlightInfoFareEntity(
      grossFare: 0,
      netFare: 0,
      totalBaseFare: 0,
      totalTax: 0,
      totalServiceTax: 0,
      totalTransactionFee: 0,
      totalCommission: 0,
    );
    return AkFlightInfoJourneyEntity(
      provider: '',
      stops: stops,
      orderId: 1,
      grossFare: 0,
      netFare: 0,
      duration: duration,
      promo: '',
      fareType: widget.tripType,
      segments: [AkFlightInfoSegmentEntity(flight: flight, fare: fare)],
    );
  }

  /// Converts a raw duration value to the "Xh Ym" format [_cleanDuration] expects.
  /// Handles plain minutes ("95"), ISO-style ("PT1H35M"), and already-formatted strings.
  String _durationToMinutesStr(String raw) {
    if (raw.isEmpty) return '';
    // Plain integer minutes → convert to "Xh Ym".
    final mins = int.tryParse(raw.trim());
    if (mins != null && mins > 0) {
      final h = mins ~/ 60;
      final m = mins % 60;
      if (h > 0 && m > 0) return '${h}h ${m}m';
      if (h > 0) return '${h}h';
      return '${m}m';
    }
    return raw;
  }

  Widget _loadedContent(
    BuildContext context,
    AkFlightInfoEntity data, [
    AkGetSPricerEntity? pricerData,
    bool switching = false,
  ]) {
    final firstJourney =
        data.trips.isNotEmpty && data.trips.first.journey.isNotEmpty
        ? data.trips.first.journey.first
        : null;

    if (firstJourney == null || firstJourney.segments.isEmpty) {
      return _errorState(context, 'No flight details available for this fare.');
    }

    // One resolved journey per leg (Onward, Return, or each multi-city leg).
    final legJourneys = <AkFlightInfoJourneyEntity>[
      firstJourney,
      for (final trip in data.trips.skip(1))
        if (trip.journey.isNotEmpty && trip.journey.first.segments.isNotEmpty)
          trip.journey.first,
    ];

    // Use the active tab's journey for per-leg details (route card, baggage,
    // book button). Falls back to leg 1 when FlightInfo didn't return that leg.
    final totalLegs = 1 + _additionalLegs.length;
    final activeTab = _selectedLegTab.clamp(0, totalLegs - 1);
    final journey = activeTab < legJourneys.length
        ? legJourneys[activeTab]
        : firstJourney;

    final segments = journey.segments;
    final isFullyRefundable = segments.every(
      (s) => s.flight.refundable.toUpperCase() == 'Y',
    );
    final fareChanged = pricerData?.fareChanged ?? false;

    final sorted = [..._fareOptions]
      ..sort((a, b) => a.amount.compareTo(b.amount));
    final displayed = _capFareOptions(sorted);

    return Column(
      children: [
        if (fareChanged) _fareChangedBanner(context),
        if (fareChanged) SizedBox(height: context.h(10)),
        _activeRouteCard(context, legJourneys, data, pricerData),
        SizedBox(height: context.h(20)),
        if (_fareOptions.length > 1) ...[
          _fareSelector(context),
          SizedBox(height: context.h(30)),
        ],
        // MMT-style: all fare cards stacked vertically, each with its own
        // price-drop toggle, book button, and promo strip.
        for (final option in displayed) ...[
          switching
              ? _fareFamilyCardShimmer(context)
              : _fareFamilyDetailCardForOption(
                  context,
                  option: option,
                  pricerData: pricerData,
                  isFullyRefundable: isFullyRefundable,
                  data: data,
                  journey: journey,
                  fareChanged: fareChanged,
                  rank: displayed.indexOf(option),
                  total: displayed.length,
                ),
          SizedBox(height: context.h(16)),
        ],
      ],
    );
  }

  /// Per-leg route card for round trip / multi-city — same layout as
  /// [_flightRouteCard]. Which leg is shown is now driven by the ONWARD/
  /// RETURN tab bar (see `_legTabBar`/`_selectedLegTab`) instead of a label
  /// stacked above every leg's own card, since a return or connecting leg
  /// can be a different airline/flight number than whatever the user
  /// originally tapped.
  Widget _legRouteCard(
    BuildContext context, {
    required AkFlightInfoJourneyEntity journey,
  }) {
    final segments = journey.segments;
    if (segments.isEmpty) return const SizedBox.shrink();

    final firstFlight = segments.first.flight;
    final lastFlight = segments.last.flight;
    final airlineCode = _airlineCodeOf(firstFlight);
    final airlineName = _marketingSegment(
      firstFlight.airline,
      fallback: airlineCode,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: _stroke, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _routeGradientHeader(
            context,
            fromCode: firstFlight.departureCode,
            fromName: _shortCityName(firstFlight.depAirportName),
            toCode: lastFlight.arrivalCode,
            toName: _shortCityName(lastFlight.arrAirportName),
          ),
          _routeAirlineRow(
            context,
            airlineCode: airlineCode,
            airlineName: airlineName,
            flightNo: '$airlineCode${firstFlight.flightNo}',
            aircraft: firstFlight.aircraft.isNotEmpty
                ? firstFlight.aircraft
                : firstFlight.equipmentType,
            cabin: firstFlight.cabin,
          ),
          Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _timeLocation(
                        context,
                        time: _formatTime(firstFlight.departureTime),
                        code: '',
                        name: _formatDate(firstFlight.departureTime),
                        extra:
                            '${firstFlight.departureCode}${firstFlight.departureTerminal.isNotEmpty ? ', Terminal ${firstFlight.departureTerminal}' : ''}',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _flightPathWithStops(
                        context,
                        segments,
                        duration: _cleanDuration(
                          journey.duration,
                          depTime: firstFlight.departureTime,
                          arrTime: lastFlight.arrivalTime,
                        ),
                        journeyStops: journey.stops,
                      ),
                    ),
                    Expanded(
                      child: _timeLocation(
                        context,
                        time: _formatTime(lastFlight.arrivalTime),
                        code: '',
                        name: _formatDate(lastFlight.arrivalTime),
                        extra:
                            '${lastFlight.arrivalCode}${lastFlight.arrivalTerminal.isNotEmpty ? ', Terminal ${lastFlight.arrivalTerminal}' : ''}',
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(24)),
                _routeDetailsFooter(
                  context,
                  expanded: _flightDetailsExpanded,
                  onToggle: () => setState(
                    () => _flightDetailsExpanded = !_flightDetailsExpanded,
                  ),
                ),
                if (_flightDetailsExpanded)
                  _expandedFlightDetails(context, segments, journey, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shared by [_fareFamilyDetailCard] and [_expandedFlightDetails] so both
  /// read the same real GetSPricer baggage allowance instead of faking it.
  AkGetSPricerBaggageEntity? _includedBaggageFor(
    AkGetSPricerEntity? pricerData,
  ) {
    if (pricerData == null || pricerData.includedBaggage.isEmpty) return null;
    // One trip per leg, in tab order. Reading trips.first for every tab is
    // what made the RETURN tab quote the outbound flight's allowance.
    final trips = pricerData.trips;
    if (trips.isEmpty) return null;
    final trip = trips[_activeLegTab.clamp(0, trips.length - 1)];
    if (trip.journey.isEmpty || trip.journey.first.segments.isEmpty)
      return null;
    final fuid = trip.journey.first.segments.first.flight.fuid;
    final baggage = pricerData.includedBaggage[fuid.toString()];
    if (baggage == null) return null;
    return baggage['ADT'] ?? baggage.values.first;
  }

  /// What the open leg's fare includes.
  ///
  /// GetSPricer's `included_baggage` is the precise source — per segment, per
  /// passenger type — but it only exists once SmartPricer has run, and the RT
  /// flow defers that to booking time so it doesn't spend its one non-preview
  /// call early. That left round trips with no allowance to show at all, so
  /// FareFamilyDetails' per-fare figures stand in; only when neither has
  /// anything do we fall back to the airline's own rules.
  ({String? checkin, String? cabin}) _baggageForActiveLeg(
    AkGetSPricerEntity? pricerData,
  ) {
    final priced = _includedBaggageFor(pricerData);
    if (priced != null &&
        (priced.checkin.isNotEmpty || priced.cabin.isNotEmpty)) {
      return (
        checkin: priced.checkin.isEmpty ? null : priced.checkin,
        cabin: priced.cabin.isEmpty ? null : priced.cabin,
      );
    }
    final family = _fareFamilyBaggage[_activeLegIndex];
    return (checkin: family?['checkin'], cabin: family?['cabin']);
  }

  /// Adds the unit only when the API gave a bare number — plenty of these
  /// already arrive as "15Kg", which was rendering as "15Kg kg".
  String _withKg(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    return RegExp(r'^\d+(\.\d+)?$').hasMatch(v) ? '$v kg' : v;
  }

  String _checkinBaggageText(AkGetSPricerEntity? pricerData) {
    final checkin = _baggageForActiveLeg(pricerData).checkin;
    return (checkin == null || checkin.isEmpty)
        ? 'As per airline'
        : _withKg(checkin);
  }

  String _cabinBaggageText(AkGetSPricerEntity? pricerData) {
    final cabin = _baggageForActiveLeg(pricerData).cabin;
    return (cabin == null || cabin.isEmpty) ? 'As per airline' : _withKg(cabin);
  }

  // ==================== FARE FAMILY DETAIL CARD (Figma: "Saver" + RECOMMENDED) ====================
  Widget _fareFamilyDetailCard(
    BuildContext context,
    AkGetSPricerEntity? pricerData,
    bool isFullyRefundable,
  ) {
    final checkin = _checkinBaggageText(pricerData);
    final cabinBag = _cabinBaggageText(pricerData);

    final sorted = [..._fareOptions]
      ..sort((a, b) => a.amount.compareTo(b.amount));
    final displayed = _capFareOptions(sorted);
    final rank = displayed.isEmpty
        ? 0
        : displayed
              .indexWhere((o) => o.index == _activeLegIndex)
              .clamp(0, displayed.length - 1);
    final familyLabel = _getFareLabel(
      displayed.isNotEmpty
          ? displayed[rank]
          : FareFamilyIndexEntity(
              index: _activeLegIndex,
              amount: _activeLegAmount,
              refundable: isFullyRefundable,
            ),
      rank,
      displayed.isNotEmpty ? displayed.length : 1,
    );
    final isCheapest = rank == 0;

    // Same reasoning as _fareCard: Figma positions the RECOMMENDED badge off
    // the card's own border (`top: -10.5px` on a `p-20` card), so the Stack
    // needs to wrap the whole card rather than sit inside its padding.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.w(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: _stroke, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        familyLabel,
                        style: TextStyle(
                          color: _title900,
                          fontSize: context.fs(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Essential travel benefits',
                        style: TextStyle(
                          color: AppColors.subhead,
                          fontSize: context.fs(12),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        context.money(_activeLegAmount),
                        style: TextStyle(
                          color: _title900,
                          fontSize: context.fs(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _fareCoverageLabel,
                        style: TextStyle(
                          color: AppColors.subhead,
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: context.h(16)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _fareFamilyGridItem(
                      context,
                      icon: Icons.work_outline,
                      color: AppColors.subhead,
                      title: 'Cabin Bag',
                      subtitle: '$cabinBag included',
                    ),
                  ),
                  SizedBox(width: context.w(16)),
                  Expanded(
                    child: _fareFamilyGridItem(
                      context,
                      icon: Icons.luggage_outlined,
                      color: AppColors.subhead,
                      title: 'Check-in',
                      subtitle: '$checkin included',
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(16)),
              BlocBuilder<AkFareRuleBloc, AkFareRuleState>(
                bloc: _fareRuleBloc,
                builder: (context, state) {
                  final loading =
                      state is AkFareRuleLoading || state is AkFareRuleInitial;
                  final texts = state is AkFareRuleLoaded
                      ? state.data.ruleTexts
                      : const <String>[];
                  // Was hardcoded to always claim "Free date change"/free
                  // cancellation — the FareRule bloc is already requested
                  // (see _loadFareRule) but its response was never read
                  // anywhere in this screen. Non-refundable/no-change fares
                  // exist, so a blanket "free" claim on a payment screen is a
                  // real bug.
                  final cancelFee = _extractFeeText(texts, const [
                    'cancellation',
                    'cancel',
                  ]);
                  final changeFee = _extractFeeText(texts, const [
                    'change',
                    'reissue',
                  ]);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _fareFamilyGridItem(
                          context,
                          icon: Icons.event_busy_outlined,
                          color: AppColors.OrangeColor,
                          title: 'Cancellation',
                          subtitle: loading
                              ? 'Checking…'
                              : (cancelFee ??
                                    (isFullyRefundable
                                        ? 'Free'
                                        : 'As per fare rules')),
                        ),
                      ),
                      SizedBox(width: context.w(16)),
                      Expanded(
                        child: _fareFamilyGridItem(
                          context,
                          icon: Icons.event_repeat_outlined,
                          color: AppColors.AppBlue,
                          title: 'Date Change',
                          subtitle: loading
                              ? 'Checking…'
                              : (changeFee ?? 'As per fare rules'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        if (isCheapest)
          Positioned(
            left: context.w(17.5),
            top: -context.h(10.5),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                color: AppColors.AppBlue,
                borderRadius: BorderRadius.circular(context.r(9999)),
              ),
              child: Text(
                'RECOMMENDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== FARE CARD SHIMMER (shown while switching fare) ====================
  Widget _fareFamilyCardShimmer(BuildContext context) {
    Widget bar({
      double width = double.infinity,
      double height = 12,
      double radius = 6,
    }) => _ShimmerBox(
      width: width,
      height: context.h(height),
      radius: context.r(radius),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: _stroke, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              context.h(20),
              context.w(20),
              context.h(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(width: context.w(90), height: 14),
                    SizedBox(height: context.h(6)),
                    bar(width: context.w(130), height: 10),
                  ],
                ),
                bar(width: context.w(70), height: 14),
              ],
            ),
          ),
          // 2×2 grid
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              0,
              context.w(20),
              context.h(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: bar(height: 36, radius: 8)),
                    SizedBox(width: context.w(16)),
                    Expanded(child: bar(height: 36, radius: 8)),
                  ],
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Expanded(child: bar(height: 36, radius: 8)),
                    SizedBox(width: context.w(16)),
                    Expanded(child: bar(height: 36, radius: 8)),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.8, color: _stroke),
          // Toggle row
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(14),
              context.w(16),
              context.h(14),
            ),
            child: Row(
              children: [
                _ShimmerBox(
                  width: context.w(36),
                  height: context.w(36),
                  radius: context.r(18),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(width: context.w(140), height: 12),
                      SizedBox(height: context.h(5)),
                      bar(width: context.w(90), height: 10),
                    ],
                  ),
                ),
                _ShimmerBox(
                  width: context.w(44),
                  height: context.h(24),
                  radius: context.r(12),
                ),
              ],
            ),
          ),
          // Book button
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              0,
              context.w(16),
              context.h(16),
            ),
            child: bar(height: 44, radius: 12),
          ),
          // Promo strip
          Container(
            width: double.infinity,
            height: context.h(40),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(context.r(16)),
                bottomRight: Radius.circular(context.r(16)),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(10),
            ),
            child: bar(width: context.w(200), height: 10),
          ),
        ],
      ),
    );
  }

  // ==================== MMT-STYLE PER-FARE CARD (fare detail + toggle + book + promo) ====================
  Widget _fareFamilyDetailCardForOption(
    BuildContext context, {
    required FareFamilyIndexEntity option,
    required AkGetSPricerEntity? pricerData,
    required bool isFullyRefundable,
    required AkFlightInfoEntity data,
    required AkFlightInfoJourneyEntity journey,
    required bool fareChanged,
    required int rank,
    required int total,
  }) {
    final isSelected = option.index == _activeLegIndex;
    final isCheapest = rank == 0;
    final familyLabel = _getFareLabel(option, rank, total);
    final checkin = _checkinBaggageText(pricerData);
    final cabinBag = _cabinBaggageText(pricerData);

    // Book-readiness mirrors _bookButton but evaluated per-card.
    final ft = widget.tripType;
    final bookingReady = switch (ft) {
      'DM' || 'IM' => !_switchingFare && !_committing,
      _ => _flightInfoLoaded && !_switchingFare && !_committing,
    };

    final tripTotal = _tripNetAmount(data);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: (!isSelected && !_switchingFare)
              ? () => _selectFare(option)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(
                color: isSelected ? AppColors.AppBlue : _stroke,
                width: isSelected ? 1.5 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.AppBlue.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: context.w(12),
                  offset: Offset(0, context.h(4)),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Fare header ───────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(20),
                    context.h(20),
                    context.w(20),
                    context.h(0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              familyLabel.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: context.fs(16),
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Essential travel benefits',
                              style: TextStyle(
                                color: AppColors.subhead,
                                fontSize: context.fs(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    context.money(
                                      option.amount /
                                          (widget.travellerCount > 0
                                              ? widget.travellerCount
                                              : 1),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.AppBlue
                                          : _title900,
                                      fontSize: context.fs(16),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '/traveller',
                                  style: TextStyle(
                                    color: AppColors.subhead,
                                    fontSize: context.fs(11),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.travellerCount > 1) ...[
                              SizedBox(height: context.h(2)),
                              Text(
                                'Total: ${context.money(option.amount)} for ${widget.travellerCount} travellers',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: AppColors.subhead,
                                  fontSize: context.fs(11),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Baggage grid ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(20),
                    context.h(16),
                    context.w(20),
                    context.h(0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _fareFamilyGridItem(
                          context,
                          icon: Icons.work_outline,
                          color: AppColors.subhead,
                          title: 'Cabin Bag',
                          subtitle: '$cabinBag included',
                        ),
                      ),
                      SizedBox(width: context.w(16)),
                      Expanded(
                        child: _fareFamilyGridItem(
                          context,
                          icon: Icons.luggage_outlined,
                          color: AppColors.subhead,
                          title: 'Check-in',
                          subtitle: '$checkin included',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(20),
                    context.h(16),
                    context.w(20),
                    context.h(16),
                  ),
                  child: BlocBuilder<AkFareRuleBloc, AkFareRuleState>(
                    bloc: _fareRuleBloc,
                    builder: (context, state) {
                      final loading =
                          state is AkFareRuleLoading ||
                          state is AkFareRuleInitial;
                      final texts = state is AkFareRuleLoaded
                          ? state.data.ruleTexts
                          : const <String>[];
                      final cancelFee = _extractFeeText(texts, const [
                        'cancellation',
                        'cancel',
                      ]);
                      final changeFee = _extractFeeText(texts, const [
                        'change',
                        'reissue',
                      ]);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _fareFamilyGridItem(
                              context,
                              icon: Icons.event_busy_outlined,
                              color: AppColors.OrangeColor,
                              title: 'Cancellation',
                              subtitle: loading
                                  ? 'Checking…'
                                  : (cancelFee ??
                                        (isFullyRefundable
                                            ? 'Free'
                                            : 'As per fare rules')),
                            ),
                          ),
                          SizedBox(width: context.w(16)),
                          Expanded(
                            child: _fareFamilyGridItem(
                              context,
                              icon: Icons.event_repeat_outlined,
                              color: AppColors.AppBlue,
                              title: 'Date Change',
                              subtitle: loading
                                  ? 'Checking…'
                                  : (changeFee ?? 'As per fare rules'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // ── Divider ───────────────────────────────────────────────

                // ── Price Drop Protection toggle ──────────────────────────
                // Padding(
                //   padding: EdgeInsets.fromLTRB(
                //     context.w(16),
                //     context.h(14),
                //     context.w(16),
                //     context.h(14),
                //   ),
                //   child: Row(
                //     children: [
                //       Container(
                //         width: context.w(36),
                //         height: context.w(36),
                //         decoration: BoxDecoration(
                //           color: AppColors.AppBlue.withValues(alpha: 0.12),
                //           shape: BoxShape.circle,
                //         ),
                //         padding: EdgeInsets.all(context.w(8)),
                //         child: Image.asset(
                //           'assets/NewIcons/priceDrop.png',
                //           color: AppColors.AppBlue,
                //           fit: BoxFit.contain,
                //         ),
                //       ),
                //       SizedBox(width: context.w(10)),
                //       Expanded(
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           mainAxisSize: MainAxisSize.min,
                //           children: [
                //             Row(
                //               children: [
                //                 Flexible(
                //                   child: Text(
                //                     'Price Drop Protection',
                //                     style: TextStyle(
                //                       color: _title900,
                //                       fontSize: context.fs(13),
                //                       fontWeight: FontWeight.w700,
                //                     ),
                //                     maxLines: 1,
                //                     overflow: TextOverflow.ellipsis,
                //                   ),
                //                 ),
                //                 SizedBox(width: context.w(4)),
                //                 Icon(
                //                   Icons.info_outline,
                //                   size: context.w(13),
                //                   color: AppColors.subhead,
                //                 ),
                //               ],
                //             ),
                //             Text(
                //               'at ${context.money(469)} / adult',
                //               style: TextStyle(
                //                 color: AppColors.subhead,
                //                 fontSize: context.fs(11),
                //                 fontWeight: FontWeight.w500,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //       GestureDetector(
                //         onTap: () => setState(() {
                //           _priceDropProtection[option.index] =
                //               !(_priceDropProtection[option.index] ?? false);
                //         }),
                //         child: AnimatedContainer(
                //           duration: const Duration(milliseconds: 200),
                //           width: context.w(44),
                //           height: context.h(24),
                //           decoration: BoxDecoration(
                //             color: (_priceDropProtection[option.index] ?? false)
                //                 ? AppColors.AppBlue
                //                 : const Color(0xFFE0E0E0),
                //             borderRadius: BorderRadius.circular(context.r(12)),
                //           ),
                //           child: Align(
                //             alignment: (_priceDropProtection[option.index] ?? false)
                //                 ? Alignment.centerRight
                //                 : Alignment.centerLeft,
                //             child: Container(
                //               margin: EdgeInsets.all(context.w(2)),
                //               width: context.w(20),
                //               height: context.w(20),
                //               decoration: const BoxDecoration(
                //                 color: Colors.white,
                //                 shape: BoxShape.circle,
                //                 boxShadow: [
                //                   BoxShadow(
                //                     color: Colors.black12,
                //                     blurRadius: 4,
                //                     offset: Offset(0, 2),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // ── Book button (ONE WAY only) ─────────────────────────────
                if (widget.tripType == 'ON')
                  Divider(height: 1, thickness: 0.8, color: _stroke),
                if (widget.tripType == 'ON')
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(16),
                      context.h(10),
                      context.w(16),
                      context.h(0),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: context.h(44),
                      child: Material(
                        color: (bookingReady && isSelected)
                            ? AppColors.OrangeColor
                            : _stroke,
                        borderRadius: BorderRadius.circular(context.r(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(context.r(12)),
                          onTap: (bookingReady && isSelected)
                              ? () => _handleBookNow(
                                  context,
                                  data,
                                  journey,
                                  isFullyRefundable,
                                  fareChanged,
                                )
                              : (!isSelected && !_switchingFare)
                              ? () => _selectFare(option)
                              : null,
                          child: Center(
                            child: Text(
                              isSelected
                                  ? (bookingReady ? 'BOOK NOW' : 'LOADING…')
                                  : 'BOOK NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.fs(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // ── Promo strip: "Get flat ₹356 using TRYWNT code" ────────
                SizedBox(height: context.h(12)),
              ],
            ),
          ),
        ),
        // RECOMMENDED badge for cheapest fare
        if (isCheapest)
          Positioned(
            left: context.w(17.5),
            top: -context.h(10.5),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                color: AppColors.AppBlue,
                borderRadius: BorderRadius.circular(context.r(9999)),
              ),
              child: Text(
                'RECOMMENDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fareFamilyGridItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: context.w(16), color: color),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _title900,
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.subhead,
                  fontSize: context.fs(10),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== PRICE DROP PROTECTION (Figma) ====================
  // Purely a local UI toggle — see the field doc on `_priceDropProtection`.
  // Widget _priceDropProtectionToggle(BuildContext context) {
  //   return Container(
  //     width: double.infinity,
  //     padding: EdgeInsets.all(context.w(16.5)),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(context.r(20)),
  //       border: Border.all(color: _stroke, width: 0.5),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: context.w(40),
  //           height: context.w(40),
  //           decoration: BoxDecoration(
  //             color: AppColors.AppBlue.withValues(alpha: 0.12),
  //             shape: BoxShape.circle,
  //           ),
  //           padding: EdgeInsets.all(context.w(9)),
  //           child: Image.asset(
  //             'assets/NewIcons/priceDrop.png',
  //             color: AppColors.AppBlue,
  //             fit: BoxFit.contain,
  //           ),
  //         ),
  //         SizedBox(width: context.w(12)),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Row(
  //                 children: [
  //                   Flexible(
  //                     child: Text(
  //                       'Price Drop Protection',
  //                       style: TextStyle(
  //                         color: _title900,
  //                         fontSize: context.fs(14),
  //                         fontWeight: FontWeight.w700,
  //                       ),
  //                       maxLines: 1,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                   ),
  //                   SizedBox(width: context.w(4)),
  //                   Icon(
  //                     Icons.info_outline,
  //                     size: context.w(14),
  //                     color: AppColors.subhead,
  //                   ),
  //                 ],
  //               ),
  //               Text(
  //                 'at ${context.money(469)} / adult',
  //                 style: TextStyle(
  //                   color: AppColors.subhead,
  //                   fontSize: context.fs(12),
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         // Custom toggle switch to match the design
  //         GestureDetector(
  //           onTap: () => setState(() {
  //             _priceDropProtection['default'] =
  //                 !(_priceDropProtection['default'] ?? false);
  //           }),
  //           child: AnimatedContainer(
  //             duration: const Duration(milliseconds: 200),
  //             width: context.w(44),
  //             height: context.h(24),
  //             decoration: BoxDecoration(
  //               color: (_priceDropProtection['default'] ?? false)
  //                   ? AppColors.AppBlue
  //                   : const Color(0xFFE0E0E0),
  //               borderRadius: BorderRadius.circular(context.r(12)),
  //             ),
  //             child: Align(
  //               alignment: (_priceDropProtection['default'] ?? false)
  //                   ? Alignment.centerRight
  //                   : Alignment.centerLeft,
  //               child: Container(
  //                 margin: EdgeInsets.all(context.w(2)),
  //                 width: context.w(20),
  //                 height: context.w(20),
  //                 decoration: const BoxDecoration(
  //                   color: Colors.white,
  //                   shape: BoxShape.circle,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black12,
  //                       blurRadius: 4,
  //                       offset: Offset(0, 2),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ==================== BOOK BUTTON (Figma: flat orange "BOOK NOW") ====================
  /// Fixed bottom bar shown for all non-ONE-WAY fare types.
  /// Fixed bottom bar (non-ONE WAY fares): price + info icon on the left
  /// (taps to fare breakup sheet), CONTINUE button on the right.
  /// Matches booking_screen.dart's _buildBottomBar style exactly.
  Widget _fareBottomBar(BuildContext context) {
    return BlocBuilder<AkFlightInfoBloc, AkFlightInfoState>(
      builder: (ctx, flightState) {
        return BlocBuilder<AkGetSPricerBloc, AkGetSPricerState>(
          builder: (ctx2, pricerState) {
            AkFlightInfoEntity? data;
            AkGetSPricerEntity? pricerData;

            if (flightState is AkFlightInfoLoaded) {
              data = flightState.data;
            } else if (_cachedFlightInfo != null) {
              data = _cachedFlightInfo;
            }
            if (pricerState is AkGetSPricerLoaded) {
              pricerData = pricerState.data;
            } else if (_cachedPricerData != null) {
              pricerData = _cachedPricerData;
            }

            if (data == null) return const SizedBox.shrink();

            final tripTotal = _tripNetAmount(data);
            final ft = widget.tripType;
            final bookingReady = switch (ft) {
              'DM' || 'IM' => !_switchingFare && !_committing,
              _ => _flightInfoLoaded && !_switchingFare && !_committing,
            };

            final journeys = data.trips.expand((t) => t.journey).toList();
            final journey = journeys.isNotEmpty ? journeys.first : null;
            final isFullyRefundable = data.trips
                .expand((t) => t.journey)
                .expand((j) => j.segments)
                .every((s) => s.flight.refundable.toUpperCase() == 'Y');
            final fareChanged = pricerData?.fareChanged ?? false;

            final paxLabel = 'FOR ${widget.travellerCount} '
                '${widget.travellerCount > 1 ? 'TRAVELLERS' : 'TRAVELLER'}';

            return SafeArea(
              top: false,
              child: Container(
                height: context.h(80),
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(19),
                  vertical: context.h(12),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Left: price + info icon (tappable → fare breakup) ──
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: tripTotal > 0
                            ? () => _openFareBreakup(
                                context,
                                tripTotal,
                                flightData: data,
                                pricerData: pricerData,
                              )
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!bookingReady) ...[
                              // Shimmer skeleton while loading
                              _ShimmerBox(
                                width: context.w(100),
                                height: context.h(22),
                                radius: context.r(4),
                              ),
                              SizedBox(height: context.h(4)),
                              _ShimmerBox(
                                width: context.w(70),
                                height: context.h(10),
                                radius: context.r(3),
                              ),
                            ] else ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      context.money(tripTotal),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: context.fs(24),
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.black,
                                        letterSpacing: -0.6,
                                        height: 1.33,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: context.w(4)),
                                  Icon(
                                    Icons.info,
                                    size: context.w(12),
                                    color: AppColors.subhead,
                                  ),
                                ],
                              ),
                              Text(
                                paxLabel,
                                style: TextStyle(
                                  fontSize: context.fs(9),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.subhead,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(12)),
                    // ── Right: CONTINUE button ──────────────────────────
                    SizedBox(
                      height: context.h(44),
                      width: context.w(149),
                      child: ElevatedButton(
                        onPressed: (bookingReady && journey != null)
                            ? () => _handleBookNow(
                                context,
                                data!,
                                journey,
                                isFullyRefundable,
                                fareChanged,
                              )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.OrangeColor,
                          disabledBackgroundColor:
                              AppColors.OrangeColor.withValues(alpha: 0.6),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(12)),
                          ),
                        ),
                        child: _committing
                            ? SizedBox(
                                width: context.w(18),
                                height: context.w(18),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: context.fs(14),
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
          },
        );
      },
    );
  }


  void _openFareBreakup(
    BuildContext context,
    double tripTotal, {
    AkFlightInfoEntity? flightData,
    AkGetSPricerEntity? pricerData,
  }) {
    final adults = widget.adultCount > 0 ? widget.adultCount : 1;
    final children = widget.childCount;
    final infants = widget.infantCount;
    final totalPax = adults + children + infants;

    final lines = <FareBreakupLine>[];

    // Per-leg breakdown for multi-city (DM/IM).
    final isDmIm = widget.tripType == 'DM' || widget.tripType == 'IM';
    final legCount = 1 + _additionalLegs.length;
    double displayTotal = tripTotal;

    if (isDmIm && legCount > 1) {
      // For IM the pricer only re-prices leg 1 — its single-trip
      // grossFare is NOT per-leg, so skip it to stay consistent with
      // the fare family card's option.amount.
      final pricerTrips = widget.tripType == 'DM'
          ? (pricerData?.trips ?? [])
          : <AkGetSPricerTripEntity>[];
      final flightTrips = flightData?.trips ?? [];

      final legFares = <double>[];
      final routeLabels = <String>[];
      for (var i = 0; i < legCount; i++) {
        double legFare = 0;
        String from = '';
        String to = '';
        if (i < pricerTrips.length &&
            pricerTrips[i].journey.isNotEmpty) {
          legFare = pricerTrips[i].journey.first.grossFare;
          final segs = pricerTrips[i].journey.first.segments;
          if (segs.isNotEmpty) {
            from = segs.first.flight.departureCode;
            to = segs.last.flight.arrivalCode;
          }
        } else if (i < flightTrips.length &&
            flightTrips[i].journey.isNotEmpty) {
          legFare = flightTrips[i].journey.first.grossFare;
          final segs = flightTrips[i].journey.first.segments;
          if (segs.isNotEmpty) {
            from = segs.first.flight.departureCode;
            to = segs.last.flight.arrivalCode;
          }
        }
        if (from.isEmpty) {
          if (i == 0) {
            from = widget.fromCode;
            to = widget.toCode;
          } else if (i - 1 < _additionalLegs.length) {
            from = _additionalLegs[i - 1].flight.origin ?? '';
            to = _additionalLegs[i - 1].flight.destination ?? '';
          }
        }
        if (legFare <= 0) {
          if (i == 0) {
            legFare = _selectedAmount;
          } else if (i - 1 < _additionalLegs.length) {
            legFare = _additionalLegs[i - 1].amount;
          }
        }
        legFares.add(legFare);
        routeLabels.add(
          from.isNotEmpty && to.isNotEmpty
              ? '$from → $to'
              : 'Trip ${i + 1}',
        );
      }

      // Use the sum of per-leg gross fares as the display total so
      // the leg lines and the total are consistent.
      displayTotal = legFares.fold<double>(0, (s, f) => s + f);

      for (var i = 0; i < legCount; i++) {
        lines.add(FareBreakupLine(
          label: routeLabels[i],
          amount: context.money(legFares[i]),
        ));
      }
      lines.add(FareBreakupLine(
        label: '',
        amount: '',
      ));
    }

    // Recalculate per-pax from the display total.
    final perPaxDisplay = totalPax > 0 ? displayTotal / totalPax : displayTotal;

    // Per-pax-type breakdown.
    if (children > 0 || infants > 0) {
      final adultTotal = perPaxDisplay * adults;
      lines.add(FareBreakupLine(
        label: 'Adult(s)',
        amount: context.money(adultTotal),
        subLabel: '$adults × ${context.money(perPaxDisplay)}',
      ));
      if (children > 0) {
        final childTotal = perPaxDisplay * children;
        lines.add(FareBreakupLine(
          label: 'Child(ren)',
          amount: context.money(childTotal),
          subLabel: '$children × ${context.money(perPaxDisplay)}',
        ));
      }
      if (infants > 0) {
        final infantTotal = perPaxDisplay * infants;
        lines.add(FareBreakupLine(
          label: 'Infant(s)',
          amount: context.money(infantTotal),
          subLabel: '$infants × ${context.money(perPaxDisplay)}',
        ));
      }
    } else {
      lines.add(FareBreakupLine(
        label: 'Adult(s)',
        amount: context.money(displayTotal),
        subLabel: '$adults × ${context.money(perPaxDisplay)}',
      ));
    }

    FareBreakupSheet.show(
      context,
      lines: lines,
      totalAmount: context.money(displayTotal),
    );
  }

  Widget _bookButton(
    BuildContext context,
    AkFlightInfoEntity data,
    AkFlightInfoJourneyEntity journey,
    bool isFullyRefundable,
    bool fareChanged,
  ) {
    final ft = widget.tripType;
    // RT: ready once FlightInfo has loaded (no preview SmartPricer needed).
    //   The single allowed SmartPricer(preview=false) runs in _commitPricing().
    // DM/IM: FlightInfo always fails for multi-city; enable immediately so the
    //   user can reach _commitPricing() which handles SmartPricer at booking time.
    // ON: standard path — requires both preview SmartPricer and GetSPricer.
    final bookingReady = switch (ft) {
      // ON and RT both price at booking time now, so neither waits on a
      // preview session that no longer runs.
      'DM' || 'IM' => !_switchingFare && !_committing,
      _ => _flightInfoLoaded && !_switchingFare && !_committing,
    };

    final tripTotal = _tripNetAmount(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // The fare cards above price one leg's fare family; this is the whole
        // itinerary — every leg, every traveller — which is what actually gets
        // charged. On a round trip the two differ, and without this the page
        // headlined one leg's fare for a journey costing roughly twice that.
        if (tripTotal > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  _tripTotalLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.subhead,
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: context.w(6)),
              Text(
                context.money(tripTotal),
                style: TextStyle(
                  color: _title900,
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
        ],
        SizedBox(
          width: double.infinity,
          height: context.h(44),
          child: Material(
            color: bookingReady ? AppColors.OrangeColor : _stroke,
            borderRadius: BorderRadius.circular(context.r(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(context.r(12)),
              onTap: bookingReady
                  ? () => _handleBookNow(
                      context,
                      data,
                      journey,
                      isFullyRefundable,
                      fareChanged,
                    )
                  : null,
              child: Center(
                child: Text(
                  bookingReady ? 'BOOK NOW' : 'LOADING…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _infoChip(
    BuildContext context,
    IconData icon,
    String label, {
    double size = 14,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: const Color(0xff64748B)),
          SizedBox(width: context.w(4)),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xff475569),
              fontSize: context.fs(10),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareChangedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xffFEF3C7),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xffFCD34D)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xff92400E),
            size: context.w(16),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              'Fare has been updated. New price reflects latest fare.',
              style: TextStyle(
                color: const Color(0xff92400E),
                fontSize: context.fs(11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(40)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: const Color(0xffFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: const Color(0xffEF4444),
              size: context.w(32),
            ),
          ),
          SizedBox(height: context.h(16)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff1E293B),
              fontSize: context.fs(14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.h(8)),
          Text(
            'Please try again',
            style: TextStyle(
              color: const Color(0xff64748B),
              fontSize: context.fs(12),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: context.h(20)),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff3B82F6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: context.w(32),
                vertical: context.h(12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.flight_land,
              size: context.w(40),
              color: const Color(0xff94A3B8),
            ),
            SizedBox(height: context.h(8)),
            Text(
              'No flight details available',
              style: TextStyle(
                color: const Color(0xff64748B),
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER FUNCTIONS ====================
  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }

  String _formatDate(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      return DateFormat('dd MMM').format(DateTime.parse(isoTime));
    } catch (_) {
      return '';
    }
  }

  String _shortCityName(String name) {
    final parts = name.split('|');
    final last = parts.last.trim();
    return last.isNotEmpty ? last : name.trim();
  }

  String _cleanDuration(String duration, {String? depTime, String? arrTime}) {
    final hours =
        int.tryParse(RegExp(r'(\d+)h').firstMatch(duration)?.group(1) ?? '') ??
        0;
    final minutes =
        int.tryParse(RegExp(r'(\d+)m').firstMatch(duration)?.group(1) ?? '') ??
        0;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    // Fallback: calculate from ISO departure/arrival times
    if (depTime != null && arrTime != null) {
      try {
        final dep = DateTime.parse(depTime);
        final arr = DateTime.parse(arrTime);
        final diff = arr.difference(dep);
        if (diff.inMinutes > 0) {
          final h = diff.inHours;
          final m = diff.inMinutes % 60;
          if (h > 0 && m > 0) return '${h}h ${m}m';
          if (h > 0) return '${h}h';
          return '${m}m';
        }
      } catch (_) {}
    }
    return duration.trim();
  }

  // ==================== BUSINESS LOGIC ====================
  AkFlightInfoEntity _mergeWithPricer(
    AkFlightInfoEntity flightInfo,
    AkGetSPricerEntity pricer,
  ) {
    AkFlightInfoFlightEntity mapFlight(AkGetSPricerFlightEntity f) =>
        AkFlightInfoFlightEntity(
          fuid: f.fuid,
          vac: f.vac,
          mac: f.mac,
          oac: f.oac,
          fbc: f.fbc,
          airline: f.airline,
          flightNo: f.flightNo,
          departureTime: f.departureTime,
          arrivalTime: f.arrivalTime,
          fareClass: f.fareClass,
          departureCode: f.departureCode,
          arrivalCode: f.arrivalCode,
          departureTerminal: f.departureTerminal,
          arrivalTerminal: f.arrivalTerminal,
          depAirportName: f.depAirportName,
          arrAirportName: f.arrAirportName,
          equipmentType: f.equipmentType,
          aircraft: f.aircraft,
          rbd: f.rbd,
          cabin: f.cabin,
          refundable: f.refundable,
          seats: f.seats,
          duration: f.duration,
        );

    AkFlightInfoFareEntity mapFare(AkGetSPricerFareEntity f) =>
        AkFlightInfoFareEntity(
          grossFare: f.grossFare,
          netFare: f.netFare,
          totalBaseFare: f.totalBaseFare,
          totalTax: f.totalTax,
          totalServiceTax: f.totalServiceTax,
          totalTransactionFee: f.totalTransactionFee,
          totalCommission: f.totalCommission,
        );

    AkFlightInfoTripEntity mapTrip(AkGetSPricerTripEntity t) =>
        AkFlightInfoTripEntity(
          journey: t.journey
              .map(
                (j) => AkFlightInfoJourneyEntity(
                  provider: j.provider,
                  stops: j.stops,
                  orderId: j.orderId,
                  grossFare: j.grossFare,
                  netFare: j.netFare,
                  duration: j.duration,
                  promo: j.promo,
                  fareType: j.fareType,
                  segments: j.segments
                      .map(
                        (s) => AkFlightInfoSegmentEntity(
                          flight: mapFlight(s.flight),
                          fare: mapFare(s.fare),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        );

    return AkFlightInfoEntity(
      success: pricer.success,
      sessionId: _sessionId ?? flightInfo.sessionId,
      tui: pricer.tui,
      from: pricer.from,
      to: pricer.to,
      fromName: pricer.fromName,
      toName: pricer.toName,
      onwardDate: pricer.onwardDate,
      returnDate: pricer.returnDate,
      adultCount: pricer.adultCount,
      childCount: pricer.childCount,
      infantCount: pricer.infantCount,
      netAmount: pricer.netAmount,
      grossAmount: pricer.grossAmount,
      fareType: pricer.fareType,
      hold: flightInfo.hold,
      trips: pricer.trips.map(mapTrip).toList(),
    );
  }

  Widget _airlineLogo(
    BuildContext context,
    String code,
    String name, {
    required double size,
  }) {
    final logoCode = code.trim().toUpperCase();
    final initials = _displayAirlineCode(logoCode.isNotEmpty ? logoCode : name);

    Widget initialsTile() => Container(
      color: _airlineColor(initials),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.fs(11),
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xffE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withValues(alpha: 0.04),
            blurRadius: context.w(8),
          ),
        ],
      ),
      child: logoCode.isEmpty
          ? initialsTile()
          : Padding(
              padding: EdgeInsets.all(context.w(4)),
              child: CachedNetworkImage(
                imageUrl: 'https://images.kiwi.com/airlines/64/$logoCode.png',
                fit: BoxFit.contain,
                placeholder: (_, __) => initialsTile(),
                errorWidget: (_, __, ___) => initialsTile(),
              ),
            ),
    );
  }

  String _displayAirlineCode(String value) {
    final letters = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (letters.length >= 2) return letters.substring(0, 2);
    return letters.isEmpty ? 'FL' : letters;
  }

  Color _airlineColor(String code) {
    final colors = [
      const Color(0xffC29200),
      const Color(0xff25358D),
      const Color(0xff7A003C),
      const Color(0xff0F766E),
      const Color(0xffB42318),
    ];
    final hash = code.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return colors[hash % colors.length];
  }

  // ==================== BOOKING LOGIC ====================
  Future<void> _handleBookNow(
    BuildContext context,
    AkFlightInfoEntity data,
    AkFlightInfoJourneyEntity journey,
    bool isFullyRefundable,
    bool fareChanged,
  ) async {
    if (fareChanged && !_fareChangeAccepted) {
      final newAmount = _pricerData?.grossAmount ?? _tripNetAmount(data);
      final accepted = await _confirmFareChange(context, newAmount);
      if (!accepted) return;
      _fareChangeAccepted = true;
    }
    if (!context.mounted) return;

    final committed = await _commitPricing();
    if (!committed) return;
    if (!context.mounted) return;

    _bookNow(context, data, journey, isFullyRefundable);
  }

  Future<bool> _commitPricing() async {
    // If we already ran a successful preview=false SmartPricer+GetSPricer for
    // this fare (e.g. user went back from traveller details and tapped Book Now
    // again), reuse the cached TUI and sessionId — calling SmartPricer a second
    // time on the same search TUI returns "TUI already used / committed".
    if (_commitDone && _pricingTui != null && _sessionId != null) {
      return true;
    }

    setState(() => _committing = true);

    final isDm = widget.tripType == 'DM';

    if (isDm) {
      // DM: use MultiCity/SmartPricer/ (requires session_id from MultiCity/Search/)
      // followed by MultiCity/GetSPricer/ (requires only session_id).
      final dmSessionId = widget.searchSessionId;
      if (dmSessionId == null || dmSessionId.isEmpty) {
        if (mounted) {
          setState(() => _committing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please search again.'),
            ),
          );
        }
        return false;
      }

      final dio = sl<Dio>();
      final legs = [
        {'index': _selectedIndex, 'amount': _selectedNetAmount, 'order_id': 1},
        for (final leg in _additionalLegs)
          {
            'index': leg.resultIndex,
            'amount': leg.netAmount,
            'order_id': leg.orderId,
          },
      ];

      try {
        final spRes = await dio.post(
          Urls.multiCitySmartPricer,
          data: {'session_id': dmSessionId, 'legs': legs},
        );
        final spData = spRes.data as Map<String, dynamic>;
        if (spData['success'] != true) {
          final body = spData['error']?.toString() ?? '';
          if (mounted) {
            setState(() => _committing = false);
            final isExpired =
                body.contains('1601') ||
                body.toLowerCase().contains('no record found');
            if (isExpired) {
              _showSessionExpiredDialog(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    body.isNotEmpty
                        ? body
                        : 'Could not confirm this fare. Please try again.',
                  ),
                ),
              );
            }
          }
          return false;
        }
        _sessionId = spData['session_id']?.toString() ?? dmSessionId;

        final gspRes = await dio.post(
          Urls.multiCityGetSPricer,
          data: {'session_id': _sessionId},
        );
        final gspData = gspRes.data as Map<String, dynamic>;
        if (gspData['success'] != true) {
          if (mounted) {
            setState(() => _committing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not confirm this fare. Please try again.'),
              ),
            );
          }
          return false;
        }
        // Build a minimal AkGetSPricerEntity from the response so the fare
        // summary and review screen can render the total.
        _pricingTui =
            gspData['TUI']?.toString() ?? gspData['tui']?.toString() ?? '';
        _pricerData = AkGetSPricerModel.fromJson(gspData);
        _commitDone = true;
        if (mounted) setState(() => _committing = false);
        return true;
      } on DioException catch (e) {
        if (mounted) {
          setState(() => _committing = false);
          final body =
              e.response?.data?['error']?.toString() ?? e.message ?? '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                body.isNotEmpty
                    ? body
                    : 'Could not confirm this fare. Please try again.',
              ),
            ),
          );
        }
        return false;
      }
    }

    // ON/RT/RS/IM: standard SmartPricer → GetSPricer flow.
    _smartPricerBloc.add(
      LoadAkSmartPricerEvent(
        AkSmartPricerRequestEntity(
          searchTui: widget.tui,
          tripType: widget.tripType,
          trips: [
            AkSmartPricerTripRequestEntity(
              index: _selectedIndex,
              amount: _selectedNetAmount,
              orderId: 1,
            ),
            for (final leg in _additionalLegs)
              AkSmartPricerTripRequestEntity(
                index: leg.resultIndex,
                amount: leg.netAmount,
                orderId: leg.orderId,
              ),
          ],
          preview: false,
          adults: widget.adultCount > 0 ? widget.adultCount : 1,
          children: widget.childCount,
          infants: widget.infantCount,
        ),
      ),
    );

    final smartPricerState = await _smartPricerBloc.stream.firstWhere(
      (s) => s is AkSmartPricerLoaded || s is AkSmartPricerFailed,
    );
    if (smartPricerState is! AkSmartPricerLoaded) {
      if (mounted) {
        setState(() => _committing = false);
        final dioErr = (smartPricerState as AkSmartPricerFailed).error;
        final body = dioErr.response?.data?.toString() ?? dioErr.message ?? '';
        final isExpired =
            body.contains('1601') ||
            body.toLowerCase().contains('no record found');
        if (isExpired) {
          _showSessionExpiredDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not confirm this fare. Please try again.'),
            ),
          );
        }
      }
      return false;
    }
    _sessionId = smartPricerState.data.sessionId;

    // Claim the pricer for this call before dispatching, so no other path can
    // slip a second request onto the same bloc while we wait for ours.
    _pricerRequested = true;
    _pricerBloc.add(
      LoadAkGetSPricerEvent(
        AkGetSPricerRequestEntity(
          tui: smartPricerState.data.tui,
          preview: false,
        ),
      ),
    );

    final pricerState = await _pricerBloc.stream.firstWhere(
      (s) => s is AkGetSPricerLoaded || s is AkGetSPricerFailed,
    );
    if (pricerState is! AkGetSPricerLoaded) {
      if (mounted) {
        setState(() {
          _committing = false;
          // Let the next Book Now tap run the whole commit again rather than
          // reusing a half-finished one — a timed-out GetSPricer leaves the
          // fare uncommitted at Akbar even though SmartPricer succeeded.
          _commitDone = false;
          _pricerRequested = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not confirm this fare. Please try again.'),
          ),
        );
      }
      return false;
    }
    _pricingTui = pricerState.data.tui;
    _pricerData = pricerState.data;
    _commitDone = true;

    if (mounted) setState(() => _committing = false);
    return true;
  }

  /// Turns a FlightInfo failure into something a traveller can act on.
  ///
  /// The raw `DioException.message` is a paragraph about status codes and
  /// `validateStatus` — correct for a developer, meaningless on a booking
  /// screen. Akbar's own wording is surfaced when it is useful, and its
  /// "No Record found" (an expired or spent search) is translated into the
  /// one thing that actually fixes it: search again.
  String _flightInfoErrorText(DioException error) {
    final body = error.response?.data?.toString() ?? '';
    if (body.contains('No Record found') ||
        body.contains('1601') ||
        body.toLowerCase().contains('no record')) {
      return 'This search has expired. Please go back and search again for '
          'the latest fares.';
    }
    if (error.response?.statusCode != null) {
      return 'We could not load this fare right now. Please try again in a '
          'moment.';
    }
    return 'Could not reach the server. Check your connection and try again.';
  }

  void _showSessionExpiredDialog(BuildContext context) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fare No Longer Available'),
        content: const Text(
          'The airline could not confirm this fare just now. It may have sold '
          'out or the price may have moved.\n\nPick another fare, or search '
          'again for the latest prices.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Pop past detail popup back to the search results screen.
              // popUntil handles the case where the user is anywhere in the
              // booking stack (detail popup is always a direct push from results).
              Navigator.of(context).popUntil(
                (route) => route.isFirst || route.settings.name == '/',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Results'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmFareChange(
    BuildContext context,
    double newAmount,
  ) async {
    final wantsToContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fare Updated'),
        content: Text(
          'The price for this flight has changed to ${context.money(newAmount)}. '
          'Do you want to continue with the new fare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept & Continue'),
          ),
        ],
      ),
    );
    if (wantsToContinue != true) return false;

    // _sessionId may be null when GetSPricer returned Code 1500 with no
    // session_id. In that case there is no fare-change session to accept on
    // Akbar's side, but the user has already seen and agreed to the new price
    // in the dialog above — proceed as accepted.
    if (_sessionId == null) return true;

    final result = await sl<AkAcceptFareChangeUseCase>().call(
      AkAcceptFareChangeRequestEntity(sessionId: _sessionId!),
    );
    if (result is DataSuccess<AkAcceptFareChangeEntity> &&
        result.data?.success == true) {
      return true;
    }
    // "No fare change is pending on this session" means Akbar's session has
    // already moved past the fare-change state (e.g. accepted in a prior call
    // or the session expired). The user has confirmed the new price, so treat
    // this as a benign no-op and continue.
    final dioErr = (result is DataFailed) ? result.error : null;
    final errMsg = (dioErr?.response?.data?.toString() ?? dioErr?.message ?? '')
        .toLowerCase();
    if (errMsg.contains('no fare change is pending') ||
        errMsg.contains('no fare change')) {
      return true;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not confirm the new fare. Please try again.'),
        ),
      );
    }
    return false;
  }

  void _bookNow(
    BuildContext context,
    AkFlightInfoEntity data,
    AkFlightInfoJourneyEntity journey,
    bool isFullyRefundable,
  ) {
    // For DM/IM use _pricerData.netAmount (the real total) if available,
    // since minEntity.netAmount may only reflect the active leg's fare.
    // final isDmIm = widget.tripType == 'DM' || widget.tripType == 'IM';
    // final netAmt = isDmIm && _pricerData != null && _pricerData!.grossAmount > 0
    //     ? _pricerData!.grossAmount
    //     : data.grossAmount;
    // final totalPrice = '₹${netAmt.toStringAsFixed(0)}';
    final isDmIm = widget.tripType == 'DM' || widget.tripType == 'IM';
    double grossAmt;
    if (widget.tripType == 'IM') {
      // IM: GetSPricer re-prices only leg 1 — its grossAmount is NOT the
      // whole journey. Use the same selected-leg sum the UI displayed.
      // Exception: when a fare change was accepted (Code 1500), GetSPricer
      // returns the repriced total for the whole journey — use that.
      if (_fareChangeAccepted && _pricerData != null && _pricerData!.grossAmount > 0) {
        grossAmt = _pricerData!.grossAmount;
      } else {
        grossAmt = _selectedAmount +
            _additionalLegs.fold<double>(0, (sum, leg) => sum + leg.amount);
      }
    } else if (isDmIm && _pricerData != null && _pricerData!.grossAmount > 0) {
      grossAmt = _pricerData!.grossAmount;
    } else {
      grossAmt = data.grossAmount;
    }
    final totalPrice = '₹${grossAmt.toStringAsFixed(0)}';
    Navigator.pop(context);

    // Build additional-leg routes from FlightInfo trips when available.
    // For DM/IM, fall back to _additionalLegs when data.trips only has
    // the first leg (happens when _dmImWidgetContent's minEntity was used).
    List<FlightRouteSegment> additionalLegRoutes;
    if (data.trips.length > 1) {
      additionalLegRoutes = data.trips
          .asMap()
          .entries
          .skip(1)
          .where(
            (e) =>
                e.value.journey.isNotEmpty &&
                e.value.journey.first.segments.isNotEmpty,
          )
          .map((e) {
            final tripIndex = e.key;
            final trip = e.value;
            final legJourney = trip.journey.first;
            final legSegments = legJourney.segments;
            final legFirstFlight = legSegments.first.flight;
            final legLastFlight = legSegments.last.flight;
            return FlightRouteSegment(
              from: legFirstFlight.departureCode,
              to: legLastFlight.arrivalCode,
              fromCity: _shortCityName(legFirstFlight.depAirportName),
              toCity: _shortCityName(legLastFlight.arrAirportName),
              departureTime: _formatTime(legFirstFlight.departureTime),
              arrivalTime: _formatTime(legLastFlight.arrivalTime),
              departureDate: _formatDate(legFirstFlight.departureTime),
              duration: _cleanDuration(
                legJourney.duration,
                depTime: legFirstFlight.departureTime,
                arrTime: legLastFlight.arrivalTime,
              ),
              airline: _marketingSegment(
                legFirstFlight.airline,
                fallback: legFirstFlight.airline,
              ),
              flightNo:
                  "${_airlineCodeOf(legFirstFlight)} • ${legFirstFlight.flightNo}",
              price: '₹${legJourney.grossFare.toStringAsFixed(0)}',
              stops: legJourney.stops,
              viaAirports: _viaAirportsOf(legSegments),
              isRefundable: legSegments.every(
                (s) => s.flight.refundable.toUpperCase() == 'Y',
              ),
              searchTui: widget.tui,
              pricingTui: _pricingTui,
              sessionId: _sessionId,
              amount: legJourney.grossFare,
              akFareData: _pricerData,
              legIndex: tripIndex,
            );
          })
          .toList();
    } else if (isDmIm && _additionalLegs.isNotEmpty) {
      // FlightInfo didn't return multi-trip data — build from _additionalLegs
      // which always carries every selected leg's FlightEntity.
      additionalLegRoutes = _additionalLegs.asMap().entries.map((e) {
        final i = e.key; // 0-based within additionalLegs
        final leg = e.value;
        final f = leg.flight;
        return FlightRouteSegment(
          from: f.origin ?? '',
          to: f.destination ?? '',
          fromCity: f.originName ?? f.origin ?? '',
          toCity: f.destinationName ?? f.destination ?? '',
          departureTime: _formatTime(f.departureTime ?? ''),
          arrivalTime: _formatTime(f.arrivalTime ?? ''),
          departureDate: _formatDate(f.departureTime ?? ''),
          duration: f.duration ?? '',
          airline: f.airlineName ?? '',
          flightNo: '${f.airlineCode ?? ''} • ${f.flightNumber ?? ''}',
          price: '₹${leg.amount.toStringAsFixed(0)}',
          stops: f.stops ?? 0,
          searchTui: widget.tui,
          pricingTui: _pricingTui,
          sessionId: _sessionId,
          amount: leg.amount,
          akFareData: _pricerData,
          legIndex: i + 1, // trips[1], trips[2], …
        );
      }).toList();
    } else {
      additionalLegRoutes = const [];
    }

    final segments = journey.segments;
    final firstFlight = segments.first.flight;
    final lastFlight = segments.last.flight;
    final fromCity = _shortCityName(firstFlight.depAirportName);
    final toCity = _shortCityName(lastFlight.arrAirportName);

    final route = FlightRouteSegment(
      from: firstFlight.departureCode,
      to: lastFlight.arrivalCode,
      fromCity: fromCity, // NEW - pass city name
      toCity: toCity,
      price: totalPrice,
      traceId: widget.traceId,
      resultIndex: widget.resultIndex,
      departureTime: _formatTime(firstFlight.departureTime),
      arrivalTime: _formatTime(lastFlight.arrivalTime),
      departureDate: _formatDate(firstFlight.departureTime),
      duration: _cleanDuration(
        journey.duration,
        depTime: firstFlight.departureTime,
        arrTime: lastFlight.arrivalTime,
      ),
      airline: _marketingSegment(
        firstFlight.airline,
        fallback: widget.airlineName,
      ),
      flightNo: "${_airlineCodeOf(firstFlight)} • ${firstFlight.flightNo}",
      stops: journey.stops,
      viaAirports: _viaAirportsOf(segments),
      isRefundable: isFullyRefundable,
      searchTui: widget.tui,
      pricingTui: _pricingTui,
      sessionId: _sessionId,
      amount: grossAmt > 0 ? grossAmt : widget.amount,
      // amount: netAmt > 0 ? netAmt : widget.amount,
      akFareData: _pricerData,
    );

    // Search → Booking → Add-ons → Payment: the booking screen collects
    // traveller details first and pushes [SeatAddonsScreen] itself, so that
    // SelectSeats/SelectSSR still run before CreateItinerary prices the
    // session.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlightBookingScreen(
          routes: [route, ...additionalLegRoutes],
          totalPrice: totalPrice,
          traceId: widget.traceId,
          resultIndex: widget.resultIndex,
          price: totalPrice,
          travellerCount: widget.travellerCount,
          // Prefer the SearchCard's own split; fall back to what GetSPricer
          // echoed back for this fare when the caller didn't pass one.
          adultCount: widget.adultCount > 0
              ? widget.adultCount
              : (data.adultCount > 0 ? data.adultCount : 0),
          childCount: widget.childCount > 0
              ? widget.childCount
              : data.childCount,
          infantCount: widget.infantCount > 0
              ? widget.infantCount
              : data.infantCount,
          isLoggedIn: false,
          fareType: widget.tripType,
        ),
      ),
    );
  }

  String _airlineCodeOf(AkFlightInfoFlightEntity flight) =>
      flight.mac.isNotEmpty ? flight.mac : flight.vac;

  List<String> _viaAirportsOf(List<AkFlightInfoSegmentEntity> segments) {
    if (segments.length <= 1) return const [];
    return segments
        .sublist(0, segments.length - 1)
        .map((s) => s.flight.arrivalCode)
        .toList();
  }

  /// Returns a compact layover string for all connection points, e.g.
  /// "Layover: BOM 1h 20m · DEL 3h 05m"
  String _layoverSummary(List<AkFlightInfoSegmentEntity> segments) {
    if (segments.length <= 1) return '';
    final parts = <String>[];
    for (int i = 0; i < segments.length - 1; i++) {
      final arr = segments[i].flight.arrivalTime;
      final dep = segments[i + 1].flight.departureTime;
      final code = segments[i].flight.arrivalCode;
      String layover = '';
      try {
        if (arr.isNotEmpty && dep.isNotEmpty) {
          final arrDt = DateTime.parse(arr);
          final depDt = DateTime.parse(dep);
          final diff = depDt.difference(arrDt);
          if (diff.inMinutes > 0) {
            final h = diff.inHours;
            final m = diff.inMinutes % 60;
            layover = h > 0
                ? '${h}h ${m.toString().padLeft(2, '0')}m'
                : '${m}m';
          }
        }
      } catch (_) {}
      parts.add(layover.isNotEmpty ? '$code $layover' : code);
    }
    return 'Layover: ${parts.join(' · ')}';
  }

  String _marketingSegment(String value, {required String fallback}) {
    final parts = value.split('|').map((p) => p.trim()).toList();
    if (parts.length > 1 && parts[1].isNotEmpty) return parts[1];
    final firstNonEmpty = parts.firstWhere(
      (p) => p.isNotEmpty,
      orElse: () => '',
    );
    return firstNonEmpty.isNotEmpty ? firstNonEmpty : fallback;
  }

  /// Best-effort extraction of a fee value from FareRule's free-text rule
  /// lines (the API doc doesn't pin down a structured fee field). Prefers a
  /// currency amount; when a line matches the keyword but carries no amount
  /// (e.g. "Non Refundable"), falls back to that short verdict text. Returns
  /// null only when no line matches any keyword at all.
  String? _extractFeeText(List<String> ruleTexts, List<String> keywords) {
    for (final line in ruleTexts) {
      final lower = line.toLowerCase();
      if (!keywords.any((k) => lower.contains(k))) continue;

      final match = RegExp(r'(₹|INR|Rs\.?)\s?[\d,]+(\.\d+)?').firstMatch(line);
      if (match != null) return '${match.group(0)} onwards';

      final parts = line
          .split('—')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.isNotEmpty && parts.last.length <= 40) return parts.last;
    }
    return null;
  }

  String _getFullCabinName(String cabinCode) {
    final cabinMap = {
      'E': 'Economy',
      'Y': 'Economy',
      'M': 'Economy',
      'PE': 'Premium Economy',
      'W': 'Premium Economy',
      'B': 'Business',
      'C': 'Business',
      'F': 'First Class',
      'P': 'First Class',
    };
    return cabinMap[cabinCode.toUpperCase()] ?? cabinCode;
  }
}

// Pulsing shimmer block used by _fareFamilyCardShimmer.
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
