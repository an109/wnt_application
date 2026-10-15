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
import 'package:wander_nova/views/flight_search/domain/entities/flight_entity.dart' show FareFamilyIndexEntity;
import 'package:wander_nova/views/flight_search/domain/entities/fare_trip_type.dart';
import 'package:wander_nova/views/AKSmartPricer/domain/usecase/AKSmartPricer_usecase.dart';
import 'package:wander_nova/views/AKGetSPricer/domain/usecase/AKGetSPricer_usecase.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
import 'package:wander_nova/common_widgets/currency_scope.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../core/constants/urls.dart';

class FlightDetailsPopup extends StatefulWidget {
  final String tui;
  final String resultIndex;
  final double amount;
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

  const FlightDetailsPopup({
    super.key,
    required this.tui,
    required this.resultIndex,
    required this.amount,
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
  });

  static void show(BuildContext context, {
    required String tui,
    required String resultIndex,
    required double amount,
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
        ),
      ),
    );
  }

  @override
  State<FlightDetailsPopup> createState() => _FlightDetailsPopupState();
}

class _FlightDetailsPopupState extends State<FlightDetailsPopup> with SingleTickerProviderStateMixin {
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
  late double _selectedAmount;
  bool _switchingFare = false;
  bool _committing = false;

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

  // "Price Drop Protection" toggle (Figma). Purely local/visual — the API
  // has no such add-on today, so this doesn't change the fare or booking
  // payload. Defaults to off, matching the Figma mock.
  bool _priceDropProtection = false;

  // Animation controllers for smooth transitions
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;

  List<FareFamilyIndexEntity> get _fareOptions {
    final options = widget.fareFamilyOptions;
    if (options != null && options.isNotEmpty) return options;
    return [FareFamilyIndexEntity(index: widget.resultIndex, amount: widget.amount, refundable: true)];
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.resultIndex;
    _selectedAmount = widget.amount;

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
    _loadFareFamilyDetails();
  }

  void _loadFareFamilyDetails() {
    if (_fareOptions.isEmpty) return;
    final isDm = widget.tripType == 'DM';
    final isRt = widget.tripType == 'RT';
    final legTuis = isDm
        ? [
            widget.tui,
            for (final leg in widget.additionalLegs)
              if (leg.tui != null) leg.tui!,
          ]
        : <String>[];

    // RT: the backend requires EXACTLY 2 trips (outbound + return) in one call.
    // Sending only outbound fare options causes the backend to call SmartPricer
    // with a single trip — consuming the search TUI without caching the RT
    // pricing TUI/net_amount, causing "Net Amount Mismatch" at CreateItinerary.
    if (isRt && widget.additionalLegs.isNotEmpty) {
      final returnLeg = widget.additionalLegs.first;
      _fareFamilyDetailsBloc.add(LoadAkFareFamilyDetailsEvent(
        AkFareFamilyDetailsRequestEntity(
          tui: widget.tui,
          tuis: legTuis,
          tripType: widget.tripType,
          trips: [
            AkFareFamilyDetailsTripRequestEntity(
              index: _selectedIndex,
              amount: _selectedAmount,
              orderId: 1,
            ),
            AkFareFamilyDetailsTripRequestEntity(
              index: returnLeg.resultIndex,
              amount: returnLeg.amount,
              orderId: 2,
            ),
          ],
        ),
      ));
      return;
    }


    // Send ALL fare options so the backend returns baggage+rules for every
    // fare family, not just the currently selected one. The website does the
    // same via getOrFetchAkbarFareDetails(searchTui, allFareOptions, tripType).
    _fareFamilyDetailsBloc.add(LoadAkFareFamilyDetailsEvent(
      AkFareFamilyDetailsRequestEntity(
        tui: widget.tui,
        tuis: legTuis,
        tripType: widget.tripType,
        trips: _fareOptions
            .asMap()
            .entries
            .map((e) => AkFareFamilyDetailsTripRequestEntity(
                  index: e.value.index,
                  amount: e.value.amount,
                  orderId: e.key + 1,
                ))
            .toList(),
      ),
    ));
  }

  void _loadFareRule() {
    // For DM: collect per-leg TUIs — leg 1 = widget.tui, others from additionalLegs.
    final isDm = widget.tripType == 'DM';
    final legTuis = isDm
        ? [
            widget.tui,
            for (final leg in widget.additionalLegs)
              if (leg.tui != null) leg.tui!,
          ]
        : <String>[];

    _fareRuleBloc.add(LoadAkFareRuleEvent(
      AkFareRuleRequestEntity(
        tui: widget.tui,
        tuis: legTuis,
        trips: [
          AkFareRuleTripRequestEntity(index: _selectedIndex, amount: _selectedAmount, orderId: 1),
          for (final leg in widget.additionalLegs)
            AkFareRuleTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
        ],
      ),
    ));
  }

  void _load() {
    // For DM: each leg has its own search TUI — pass all so the backend
    // can look up each leg's index under the correct TUI.
    final isDm = widget.tripType == 'DM';
    final legTuis = isDm
        ? [
            widget.tui,
            for (final leg in widget.additionalLegs)
              if (leg.tui != null) leg.tui!,
          ]
        : <String>[];

    _bloc.add(LoadAkFlightInfoEvent(
      AkFlightInfoRequestEntity(
        tui: widget.tui,
        tripType: widget.tripType,
        tuis: legTuis,
        trips: [
          AkFlightInfoTripRequestEntity(
            index: _selectedIndex,
            amount: _selectedAmount,
            orderId: 1,
          ),
          for (final leg in widget.additionalLegs)
            AkFlightInfoTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
        ],
      ),
    ));
  }

  void _loadSmartPricer(String searchTui, {bool preview = true}) {
    _smartPricerRequested = true;

    // For DM: collect per-leg TUIs stored in FlightLegSelection.tui.
    // For IM/RT the tuis list is empty and searchTui covers all legs.
    final isDm = widget.tripType == 'DM';
    final legTuis = isDm
        ? [
            searchTui, // first leg's TUI (= widget.tui)
            for (final leg in widget.additionalLegs)
              if (leg.tui != null) leg.tui!,
          ]
        : <String>[];

    _smartPricerBloc.add(LoadAkSmartPricerEvent(
      AkSmartPricerRequestEntity(
        searchTui: searchTui,
        tripType: widget.tripType,
        trips: [
          AkSmartPricerTripRequestEntity(
            index: _selectedIndex,
            amount: _selectedAmount,
            orderId: 1,
          ),
          for (final leg in widget.additionalLegs)
            AkSmartPricerTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
        ],
        preview: preview,
        tuis: legTuis,
      ),
    ));
  }

  Future<void> _loadDmPricingPreview() async {
    _smartPricerRequested = true;
    final dmSessionId = widget.searchSessionId;
    if (dmSessionId == null || dmSessionId.isEmpty) return;

    final dio = sl<Dio>();
    final legs = [
      {'index': _selectedIndex, 'amount': _selectedAmount, 'order_id': 1},
      for (final leg in widget.additionalLegs)
        {'index': leg.resultIndex, 'amount': leg.amount, 'order_id': leg.orderId},
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

      _pricingTui = gspData['TUI']?.toString() ?? gspData['tui']?.toString() ?? '';
      _pricerData = AkGetSPricerModel.fromJson(gspData);
      _commitDone = true; // reuse this at Book Now time
      if (mounted) setState(() {});
    } catch (_) {
      // Silently ignore — _commitPricing() will retry at booking time.
    }
  }

  void _loadPricer(String smartPricerTui, {bool preview = true}) {
    _pricerRequested = true;
    _pricerBloc.add(LoadAkGetSPricerEvent(
      AkGetSPricerRequestEntity(tui: smartPricerTui, preview: preview),
    ));
  }

  void _selectFare(FareFamilyIndexEntity option) {
    if (option.index == _selectedIndex || _switchingFare) return;
    setState(() {
      _selectedIndex = option.index;
      _selectedAmount = option.amount;
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
        BlocProvider<AkFareFamilyDetailsBloc>.value(value: _fareFamilyDetailsBloc),
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
                if (widget.tripType == 'RT') {
                  setState(() => _flightInfoLoaded = true);
                } else if (widget.tripType == 'DM') {
                  // DM requires MultiCity/SmartPricer/ — standard SmartPricer
                  // returns error 300 for DM trip type.
                  _loadDmPricingPreview();
                } else {
                  _loadSmartPricer(widget.tui);
                }
              } else if (state is AkFlightInfoFailed && !_smartPricerRequested) {
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
                if (!_pricerRequested) {
                  _loadPricer(state.data.tui);
                }
              } else if (state is AkSmartPricerFailed) {
                if (_switchingFare) _switchingFare = false;
                // 1601 = Akbar session expired — show a specific message so the
                // user knows they need to re-search rather than retry.
                final body = state.error.response?.data?.toString() ?? state.error.message ?? '';
                if (body.contains('1601') || body.toLowerCase().contains('no record found')) {
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
                final labels = <String, String>{};
                final baggage = <String, Map<String, String?>>{};
                state.data.options.forEach((index, option) {
                  if (option.label != null && option.label!.isNotEmpty) {
                    labels[index] = option.label!;
                  }
                  if (option.checkin != null || option.cabin != null) {
                    baggage[index] = {
                      'checkin': option.checkin,
                      'cabin': option.cabin,
                    };
                  }
                });
                setState(() {
                  if (labels.isNotEmpty) _fareFamilyLabels = labels;
                  if (baggage.isNotEmpty) _fareFamilyBaggage = baggage;
                });
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
                  if (widget.additionalLegs.isNotEmpty)
                    _legTabBar(context, widget.additionalLegs.length + 1),
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
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
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
  // `widget.additionalLegs.isNotEmpty` guard), so it never affects one-way.
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
                          minWidth: MediaQuery.of(context).size.width / totalLegs),
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
      final leg = widget.additionalLegs[index - 1];
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
              child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xff3B82F6)),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
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
                _infoChip(context, Icons.schedule, widget.duration, size: context.w(12)),
                SizedBox(width: context.w(8)),
                _infoChip(context, Icons.sell_outlined, widget.price, size: context.w(12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FLIGHT ROUTE CARD ====================
  Widget _flightRouteCard(BuildContext context, AkFlightInfoEntity data, [AkGetSPricerEntity? pricerData]) {
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
    final airlineName = _marketingSegment(firstFlight.airline, fallback: widget.airlineName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: _stroke, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
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
            aircraft: firstFlight.aircraft.isNotEmpty ? firstFlight.aircraft : firstFlight.equipmentType,
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
                        extra: '${firstFlight.departureCode}${firstFlight.departureTerminal.isNotEmpty ? ', Terminal ${firstFlight.departureTerminal}' : ''}',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _flightPathWithStops(
                        context,
                        segments,
                        duration: _cleanDuration(journey.duration),
                      ),
                    ),
                    Expanded(
                      child: _timeLocation(
                        context,
                        time: _formatTime(lastFlight.arrivalTime),
                        code: '',
                        name: _formatDate(lastFlight.arrivalTime),
                        extra: '${lastFlight.arrivalCode}${lastFlight.arrivalTerminal.isNotEmpty ? ', Terminal ${lastFlight.arrivalTerminal}' : ''}',
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(24)),
                _routeDetailsFooter(
                  context,
                  expanded: _flightDetailsExpanded,
                  onToggle: () => setState(() => _flightDetailsExpanded = !_flightDetailsExpanded),
                ),
                if (_flightDetailsExpanded)
                  _expandedFlightDetails(context, segments, journey, pricerData),
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
          colors: [
            AppColors.AppBlue,
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 1.0],    // Simple two-color gradient
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
                  style: TextStyle(color: _title900, fontSize: context.fs(12), fontWeight: FontWeight.w500),
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
                        shape: BoxShape.circle
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
                  style: TextStyle(color: _title900, fontSize: context.fs(12), fontWeight: FontWeight.w500),
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
        final count = (constraints.maxWidth / (dashWidth + dashGap)).floor().clamp(1, 1000);
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
      padding: EdgeInsets.fromLTRB(context.w(16), context.h(16), context.w(16), context.h(17)),
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
                        style: TextStyle(color: _title900, fontSize: context.fs(14), fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (flightNo.isNotEmpty) ...[
                      SizedBox(width: context.w(4)),
                      Text(
                        flightNo,
                        style: TextStyle(color: AppColors.subhead, fontSize: context.fs(14), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
                if (aircraft.isNotEmpty)
                  Text(
                    aircraft,
                    style: TextStyle(color: AppColors.subhead, fontSize: context.fs(12), fontWeight: FontWeight.w400),
                  ),
              ],
            ),
          ),
          if (cabin.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(4)),
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
  Widget _routeDetailsFooter(BuildContext context, {required bool expanded, required VoidCallback onToggle}) {
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
              Image.asset('assets/Newimage/bag.png', width: context.w(16), height: context.w(16)),
              SizedBox(width: context.w(12)),
              Image.asset('assets/Newimage/sofa.png', width: context.w(16), height: context.w(16)),
              SizedBox(width: context.w(12)),
              Image.asset('assets/Newimage/fork.png', width: context.w(16), height: context.w(16)),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: [
                Text(
                  expanded ? 'Hide flight details' : 'View flight details',
                  style: TextStyle(color: AppColors.AppBlue, fontSize: context.fs(10), fontWeight: FontWeight.w600),
                ),
                SizedBox(width: context.w(4)),
                Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
              SizedBox(height: context.h(16)),
              _dashedLine(context, color: _stroke),
              SizedBox(height: context.h(16)),
            ],
            _segmentDetailRow(context, segments[i]),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// One connecting segment's own airline row + times row (Figma: "aIR
  /// CLICK Business with stop") — real per-segment departure/arrival/
  /// terminal/duration, not the journey total repeated per segment.
  Widget _segmentDetailRow(BuildContext context, AkFlightInfoSegmentEntity segment) {
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
                  extra: '${f.departureCode}${f.departureTerminal.isNotEmpty ? ', Terminal ${f.departureTerminal}' : ''}',
                ),
              ),
              Expanded(
                flex: 2,
                child: _segmentDurationLine(context, duration: _cleanDuration(f.duration)),
              ),
              Expanded(
                child: _timeLocation(
                  context,
                  time: _formatTime(f.arrivalTime),
                  code: '',
                  name: _formatDate(f.arrivalTime),
                  extra: '${f.arrivalCode}${f.arrivalTerminal.isNotEmpty ? ', Terminal ${f.arrivalTerminal}' : ''}',
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
  Widget _segmentDurationLine(BuildContext context, {required String duration}) {
    Widget dot() => Container(
          width: context.w(8),
          height: context.w(8),
          decoration: const BoxDecoration(color: AppColors.AppBlue, shape: BoxShape.circle),
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
              style: TextStyle(color: AppColors.subhead, fontSize: context.fs(10), fontWeight: FontWeight.w700),
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

  Widget _timeLocation(BuildContext context, {
    required String time,
    required String code,
    required String name,
    String extra = '',
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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

  Widget _flightPathWithStops(BuildContext context, List<AkFlightInfoSegmentEntity> segments, {required String duration}) {
    final isDirect = segments.length == 1;
    final stopLabel = isDirect
        ? 'NON STOP'
        : '${segments.length - 1} STOP${segments.length > 2 ? 'S' : ''}';

    Widget dot() => Container(
          width: context.w(8),
          height: context.w(8),
          decoration: const BoxDecoration(color: AppColors.AppBlue, shape: BoxShape.circle),
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
              style: TextStyle(color: AppColors.subhead, fontSize: context.fs(10), fontWeight: FontWeight.w700),
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
                        : const [AppColors.AppBlue, AppColors.AppBlue, Color(0xff94A3B8)],
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
                    '${segments.length - 1}',
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
                    gradient: LinearGradient(colors: [Color(0xff94A3B8), AppColors.AppBlue]),
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
        // Which airport(s) the stop is at — not just "how many". Shared by
        // the one-way route card and every leg's tab, so it shows both ways.
        if (!isDirect) ...[
          SizedBox(height: context.h(2)),
          Text(
            'via ${_viaAirportsOf(segments).join(', ')}',
            style: TextStyle(color: AppColors.subhead, fontSize: context.fs(9), fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ==================== SELECT FARE OPTIONS (Figma) ====================
  Widget _fareSelector(BuildContext context) {
    final sorted = [..._fareOptions]..sort((a, b) => a.amount.compareTo(b.amount));
    // Only ever show up to 3 fare cards — Saver (cheapest) / Standard
    // (middle) / Flexi (priciest) — instead of one card per raw fare
    // option, which could be 5+ and left several cards all labelled
    // "Standard" (see _getFareLabel).
    final displayed = _capFareOptions(sorted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Fare options',
          style: TextStyle(color: _title900, fontSize: context.fs(16), fontWeight: FontWeight.w600),
        ),
        SizedBox(height: context.h(16)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < displayed.length; i++) ...[
              if (i > 0) SizedBox(width: context.w(12)),
              Expanded(child: _fareCard(context, displayed[i], i, displayed.length)),
            ],
          ],
        ),
      ],
    );
  }

  /// Reduces a price-sorted fare list down to at most 3 entries: the
  /// cheapest, the priciest, and one representative in between — so
  /// [_getFareLabel]'s Saver/Standard/Flexi labels each show at most once.
  /// Lists of 3 or fewer are left untouched (still their real fares).
  List<FareFamilyIndexEntity> _capFareOptions(List<FareFamilyIndexEntity> sorted) {
    if (sorted.length <= 3) return sorted;
    final middle = sorted[sorted.length ~/ 2];
    return [sorted.first, middle, sorted.last];
  }

  Widget _fareCard(BuildContext context, FareFamilyIndexEntity option, int rank, int total) {
    final selected = option.index == _selectedIndex;
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
            width: context.w(184.5),
            // Expand height when baggage info is available
            height: hasBaggage ? context.h(94) : context.h(74),
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
                      Icon(Icons.luggage_rounded,
                          size: context.fs(11),
                          color: selected
                              ? AppColors.AppBlue.withValues(alpha: 0.75)
                              : const Color(0xff64748B)),
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
        // DM/IM: FlightInfo backend doesn't support per-leg TUI fan-out yet.
        // Treat a FlightInfo failure for these types as "skip FlightInfo" and
        // fall through to the GetSPricer-based content below instead of
        // showing an error. All real detail data comes from _mergeWithPricer.
        final flightInfoFailed = flightInfoState is AkFlightInfoFailed;
        final skipFlightInfo = flightInfoFailed && (ft == 'DM' || ft == 'IM');

        if (flightInfoFailed && !skipFlightInfo) {
          return _errorState(context, flightInfoState.error.message ?? 'Failed to load flight details');
        }
        if (flightInfoState is AkFlightInfoLoaded || skipFlightInfo) {
          return BlocBuilder<AkGetSPricerBloc, AkGetSPricerState>(
            builder: (context, pricerState) {
              if (pricerState is AkGetSPricerLoaded) {
                if (flightInfoState is AkFlightInfoLoaded) {
                  final merged = _mergeWithPricer(flightInfoState.data, pricerState.data);
                  return _loadedContent(context, merged, pricerState.data);
                }
                // DM/IM: FlightInfo failed — build a minimal AkFlightInfoEntity
                // from GetSPricer data alone so _loadedContent can render.
                final pricerOnly = _mergeWithPricer(_emptyFlightInfo(), pricerState.data);
                return _loadedContent(context, pricerOnly, pricerState.data);
              }
              if (flightInfoState is AkFlightInfoLoaded) {
                return _loadedContent(context, flightInfoState.data);
              }
              // DM/IM: FlightInfo failed + SmartPricer/GetSPricer still pending
              // or failed — show widget-data placeholder with Book Now so the
              // user can still proceed. _commitPricing() handles SmartPricer
              // (preview=false) at booking time.
              final ft = widget.tripType;
              if ((ft == 'DM' || ft == 'IM') &&
                  (pricerState is AkGetSPricerFailed || pricerState is AkGetSPricerInitial)) {
                return _dmImWidgetContent(context);
              }
              // Waiting for SmartPricer / GetSPricer — show placeholder.
              return _placeholderContent(context);
            },
          );
        }
        // FlightInfo hasn't resolved yet — show placeholder from widget data.
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
        tabIndex > 0 && tabIndex - 1 < widget.additionalLegs.length;
    final FlightLegSelection? activeLeg =
        isAdditionalLeg ? widget.additionalLegs[tabIndex - 1] : null;

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

    return Column(
      children: [
        _dmLegRouteCard(context,
            fromCode: legFrom,
            toCode: legTo,
            airlineCode: legAirlineCode,
            airlineName: legAirline,
            flightNo: legFlightNo,
            departureTime: legDep,
            arrivalTime: legArr,
            duration: legDuration),
        SizedBox(height: context.h(20)),
        _fareFamilyDetailCard(context, null, false),
        SizedBox(height: context.h(20)),
        _priceDropProtectionToggle(context),
        SizedBox(height: context.h(30)),
        // Build a minimal entity + journey from the active leg's data so
        // _bookButton / _handleBookNow can construct a FlightRouteSegment.
        Builder(builder: (ctx) {
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
                  grossFare: 0, netFare: 0, totalBaseFare: 0, totalTax: 0,
                  totalServiceTax: 0, totalTransactionFee: 0, totalCommission: 0,
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
            trips: [AkFlightInfoTripEntity(journey: [minJourney])],
          );
          return _bookButton(ctx, minEntity, minJourney, false, false);
        }),
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
              offset: const Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _routeGradientHeader(context,
              fromCode: fromCode,
              fromName: '',
              toCode: toCode,
              toName: ''),
          _routeAirlineRow(context,
              airlineCode: airlineCode,
              airlineName: airlineName,
              flightNo: flightNo,
              aircraft: '',
              cabin: ''),
          Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: Row(
              children: [
                _infoChip(context, Icons.schedule, duration,
                    size: context.w(12)),
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
    final totalLegs = 1 + widget.additionalLegs.length;
    final tab = _selectedLegTab.clamp(0, totalLegs - 1);

    if (legJourneys.length <= 1 && totalLegs == 1) {
      // Plain one-way.
      return _flightRouteCard(context, data, pricerData);
    }

    if (tab < legJourneys.length) {
      // FlightInfo returned data for this leg.
      return _legRouteCard(context, journey: legJourneys[tab]);
    }

    // DM leg beyond what FlightInfo returned — use widget data.
    if (tab == 0) {
      return _dmLegRouteCard(context,
          fromCode: widget.fromCode,
          toCode: widget.toCode,
          airlineCode: widget.airlineCode,
          airlineName: widget.airlineName,
          flightNo: widget.flightNumber,
          departureTime: widget.departureTime,
          arrivalTime: widget.arrivalTime,
          duration: widget.duration);
    }
    final leg = widget.additionalLegs[tab - 1];
    return _dmLegRouteCard(context,
        fromCode: leg.flight.origin ?? '',
        toCode: leg.flight.destination ?? '',
        airlineCode: leg.flight.airlineCode ?? '',
        airlineName: leg.flight.airlineName ?? '',
        flightNo: leg.flight.flightNumber ?? '',
        departureTime: leg.flight.departureTime ?? '',
        arrivalTime: leg.flight.arrivalTime ?? '',
        duration: leg.flight.duration ?? '');
  }

  Widget _loadedContent(BuildContext context, AkFlightInfoEntity data, [AkGetSPricerEntity? pricerData]) {
    final journey = data.trips.isNotEmpty && data.trips.first.journey.isNotEmpty
        ? data.trips.first.journey.first
        : null;

    if (journey == null || journey.segments.isEmpty) {
      return _errorState(context, 'No flight details available for this fare.');
    }

    final segments = journey.segments;
    final isFullyRefundable = segments.every((s) => s.flight.refundable.toUpperCase() == 'Y');
    final fareChanged = pricerData?.fareChanged ?? false;

    // One resolved journey per leg (Onward, Return, or each multi-city leg) —
    // matches what `_bookNow`'s additionalLegRoutes already reads from
    // data.trips.skip(1). Falls back to just the primary journey when a
    // later trip hasn't resolved yet (or genuinely is a plain one-way),
    // so the round-trip/multi-city case only ever adds cards, never removes
    // the one-way rendering below.
    final legJourneys = <AkFlightInfoJourneyEntity>[
      journey,
      for (final trip in data.trips.skip(1))
        if (trip.journey.isNotEmpty && trip.journey.first.segments.isNotEmpty) trip.journey.first,
    ];

    return Column(
      children: [
        if (fareChanged) _fareChangedBanner(context),
        if (fareChanged) SizedBox(height: context.h(10)),
        _activeRouteCard(context, legJourneys, data, pricerData),
        SizedBox(height: context.h(20)),
        if (_fareOptions.length > 1)
          BlocBuilder<AkFareFamilyDetailsBloc, AkFareFamilyDetailsState>(
            builder: (context, ffState) {
              // Only show the fare selector once the FareFamilyDetails API
              // has responded with labels. Showing it while loading or after
              // a failure would display made-up "Saver/Standard/Flexi"
              // labels that don't reflect the airline's real fare names.
              if (ffState is AkFareFamilyDetailsLoaded) {
                return Column(
                  children: [
                    _fareSelector(context),
                    SizedBox(height: context.h(30)),
                  ],
                );
              }
              if (ffState is AkFareFamilyDetailsLoading ||
                  ffState is AkFareFamilyDetailsInitial) {
                return Padding(
                  padding: EdgeInsets.only(bottom: context.h(30)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: context.w(14),
                        height: context.w(14),
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xff3B82F6)),
                      ),
                      SizedBox(width: context.w(8)),
                      Text(
                        'Loading fare options…',
                        style: TextStyle(
                          color: const Color(0xff64748B),
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Failed — omit the section entirely so no incorrect labels show.
              return const SizedBox.shrink();
            },
          ),
        _fareFamilyDetailCard(context, pricerData, isFullyRefundable),
        SizedBox(height: context.h(20)),
        _priceDropProtectionToggle(context),
        SizedBox(height: context.h(30)),
        _bookButton(context, data, journey, isFullyRefundable, fareChanged),
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
    final airlineName = _marketingSegment(firstFlight.airline, fallback: airlineCode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: _stroke, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
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
            aircraft: firstFlight.aircraft.isNotEmpty ? firstFlight.aircraft : firstFlight.equipmentType,
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
                        extra: '${firstFlight.departureCode}${firstFlight.departureTerminal.isNotEmpty ? ', Terminal ${firstFlight.departureTerminal}' : ''}',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _flightPathWithStops(
                        context,
                        segments,
                        duration: _cleanDuration(journey.duration),
                      ),
                    ),
                    Expanded(
                      child: _timeLocation(
                        context,
                        time: _formatTime(lastFlight.arrivalTime),
                        code: '',
                        name: _formatDate(lastFlight.arrivalTime),
                        extra: '${lastFlight.arrivalCode}${lastFlight.arrivalTerminal.isNotEmpty ? ', Terminal ${lastFlight.arrivalTerminal}' : ''}',
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(24)),
                _routeDetailsFooter(
                  context,
                  expanded: _flightDetailsExpanded,
                  onToggle: () => setState(() => _flightDetailsExpanded = !_flightDetailsExpanded),
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
  AkGetSPricerBaggageEntity? _includedBaggageFor(AkGetSPricerEntity? pricerData) {
    if (pricerData == null || pricerData.includedBaggage.isEmpty) return null;
    final firstFuid = pricerData.trips.isNotEmpty && pricerData.trips.first.journey.isNotEmpty
        ? (pricerData.trips.first.journey.first.segments.isNotEmpty
        ? pricerData.trips.first.journey.first.segments.first.flight.fuid
        : null)
        : null;
    if (firstFuid == null) return null;
    final baggage = pricerData.includedBaggage[firstFuid.toString()];
    if (baggage == null) return null;
    return baggage['ADT'] ?? baggage.values.first;
  }

  String _checkinBaggageText(AkGetSPricerEntity? pricerData) {
    final baggage = _includedBaggageFor(pricerData);
    return baggage != null && baggage.checkin.isNotEmpty ? '${baggage.checkin} kg' : 'As per airline';
  }

  String _cabinBaggageText(AkGetSPricerEntity? pricerData) {
    final baggage = _includedBaggageFor(pricerData);
    return baggage != null && baggage.cabin.isNotEmpty ? '${baggage.cabin}' : 'As per airline';
  }

  // ==================== FARE FAMILY DETAIL CARD (Figma: "Saver" + RECOMMENDED) ====================
  Widget _fareFamilyDetailCard(BuildContext context, AkGetSPricerEntity? pricerData, bool isFullyRefundable) {
    final checkin = _checkinBaggageText(pricerData);
    final cabinBag = _cabinBaggageText(pricerData);

    final sorted = [..._fareOptions]..sort((a, b) => a.amount.compareTo(b.amount));
    final displayed = _capFareOptions(sorted);
    final rank = displayed.isEmpty ? 0 : displayed.indexWhere((o) => o.index == _selectedIndex).clamp(0, displayed.length - 1);
    final familyLabel = _getFareLabel(
      displayed.isNotEmpty ? displayed[rank] : FareFamilyIndexEntity(index: _selectedIndex, amount: _selectedAmount, refundable: isFullyRefundable),
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
                        style: TextStyle(color: _title900, fontSize: context.fs(16), fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Essential travel benefits',
                        style: TextStyle(color: AppColors.subhead, fontSize: context.fs(12)),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        context.money(_selectedAmount),
                        style: TextStyle(color: _title900, fontSize: context.fs(16), fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '/adult',
                        style: TextStyle(color: AppColors.subhead, fontSize: context.fs(12), fontWeight: FontWeight.w500),
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
                  final loading = state is AkFareRuleLoading || state is AkFareRuleInitial;
                  final texts = state is AkFareRuleLoaded ? state.data.ruleTexts : const <String>[];
                  // Was hardcoded to always claim "Free date change"/free
                  // cancellation — the FareRule bloc is already requested
                  // (see _loadFareRule) but its response was never read
                  // anywhere in this screen. Non-refundable/no-change fares
                  // exist, so a blanket "free" claim on a payment screen is a
                  // real bug.
                  final cancelFee = _extractFeeText(texts, const ['cancellation', 'cancel']);
                  final changeFee = _extractFeeText(texts, const ['change', 'reissue']);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _fareFamilyGridItem(
                          context,
                          icon: Icons.event_busy_outlined,
                          color: AppColors.OrangeColor,
                          title: 'Cancellation',
                          subtitle: loading ? 'Checking…' : (cancelFee ?? (isFullyRefundable ? 'Free' : 'As per fare rules')),
                        ),
                      ),
                      SizedBox(width: context.w(16)),
                      Expanded(
                        child: _fareFamilyGridItem(
                          context,
                          icon: Icons.event_repeat_outlined,
                          color: AppColors.AppBlue,
                          title: 'Date Change',
                          subtitle: loading ? 'Checking…' : (changeFee ?? 'As per fare rules'),
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
              padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(4)),
              decoration: BoxDecoration(
                color: AppColors.AppBlue,
                borderRadius: BorderRadius.circular(context.r(9999)),
              ),
              child: Text(
                'RECOMMENDED',
                style: TextStyle(color: Colors.white, fontSize: context.fs(10), fontWeight: FontWeight.w700),
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
                style: TextStyle(color: _title900, fontSize: context.fs(14), fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.subhead, fontSize: context.fs(10)),
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
  Widget _priceDropProtectionToggle(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(16.5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: _stroke, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(40),
            height: context.w(40),
            decoration: BoxDecoration(
              color: AppColors.AppBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(context.w(9)),
            child: Image.asset(
              'assets/NewIcons/priceDrop.png',
              color: AppColors.AppBlue,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Price Drop Protection',
                        style: TextStyle(
                          color: _title900,
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(
                      Icons.info_outline,
                      size: context.w(14),
                      color: AppColors.subhead,
                    ),
                  ],
                ),
                Text(
                  'at ${context.money(469)} / adult',
                  style: TextStyle(
                    color: AppColors.subhead,
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Custom toggle switch to match the design
          GestureDetector(
            onTap: () => setState(() => _priceDropProtection = !_priceDropProtection),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: context.w(44),
              height: context.h(24),
              decoration: BoxDecoration(
                color: _priceDropProtection
                    ? AppColors.AppBlue
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
              child: Align(
                alignment: _priceDropProtection
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.all(context.w(2)),
                  width: context.w(20),
                  height: context.w(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOOK BUTTON (Figma: flat orange "BOOK NOW") ====================
  Widget _bookButton(BuildContext context, AkFlightInfoEntity data, AkFlightInfoJourneyEntity journey, bool isFullyRefundable, bool fareChanged) {
    final ft = widget.tripType;
    // RT: ready once FlightInfo has loaded (no preview SmartPricer needed).
    //   The single allowed SmartPricer(preview=false) runs in _commitPricing().
    // DM/IM: FlightInfo always fails for multi-city; enable immediately so the
    //   user can reach _commitPricing() which handles SmartPricer at booking time.
    // ON: standard path — requires both preview SmartPricer and GetSPricer.
    final bookingReady = switch (ft) {
      'RT' => _flightInfoLoaded && !_switchingFare && !_committing,
      'DM' || 'IM' => !_switchingFare && !_committing,
      _ => _sessionId != null && _pricingTui != null && !_switchingFare && !_committing,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // final totalAmount = data.netAmount > 0 ? data.netAmount : widget.amount;
        // Text(
        //   'Total: ₹${totalAmount.toStringAsFixed(0)}',
        //   style: TextStyle(color: AppColors.subhead, fontSize: context.fs(12), fontWeight: FontWeight.w600),
        // ),
        // SizedBox(height: context.h(8)),
        SizedBox(
          width: double.infinity,
          height: context.h(44),
          child: Material(
            color: bookingReady ? AppColors.OrangeColor : _stroke,
            borderRadius: BorderRadius.circular(context.r(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(context.r(12)),
              onTap: bookingReady
                  ? () => _handleBookNow(context, data, journey, isFullyRefundable, fareChanged)
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
  Widget _infoChip(BuildContext context, IconData icon, String label, {double size = 14}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
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
      padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(10)),
      decoration: BoxDecoration(
        color: const Color(0xffFEF3C7),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xffFCD34D)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xff92400E), size: context.w(16)),
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
              padding: EdgeInsets.symmetric(horizontal: context.w(32), vertical: context.h(12)),
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
            Icon(Icons.flight_land, size: context.w(40), color: const Color(0xff94A3B8)),
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

  String _cleanDuration(String duration) {
    final hours = int.tryParse(RegExp(r'(\d+)h').firstMatch(duration)?.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(RegExp(r'(\d+)m').firstMatch(duration)?.group(1) ?? '') ?? 0;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    return duration.trim();
  }

  // ==================== BUSINESS LOGIC ====================
  AkFlightInfoEntity _mergeWithPricer(AkFlightInfoEntity flightInfo, AkGetSPricerEntity pricer) {
    AkFlightInfoFlightEntity mapFlight(AkGetSPricerFlightEntity f) => AkFlightInfoFlightEntity(
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

    AkFlightInfoFareEntity mapFare(AkGetSPricerFareEntity f) => AkFlightInfoFareEntity(
      grossFare: f.grossFare,
      netFare: f.netFare,
      totalBaseFare: f.totalBaseFare,
      totalTax: f.totalTax,
      totalServiceTax: f.totalServiceTax,
      totalTransactionFee: f.totalTransactionFee,
      totalCommission: f.totalCommission,
    );

    AkFlightInfoTripEntity mapTrip(AkGetSPricerTripEntity t) => AkFlightInfoTripEntity(
      journey: t.journey
          .map((j) => AkFlightInfoJourneyEntity(
        provider: j.provider,
        stops: j.stops,
        orderId: j.orderId,
        grossFare: j.grossFare,
        netFare: j.netFare,
        duration: j.duration,
        promo: j.promo,
        fareType: j.fareType,
        segments: j.segments
            .map((s) => AkFlightInfoSegmentEntity(
          flight: mapFlight(s.flight),
          fare: mapFare(s.fare),
        ))
            .toList(),
      ))
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

  Widget _airlineLogo(BuildContext context, String code, String name, {required double size}) {
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
      final accepted = await _confirmFareChange(context, data.netAmount);
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
            const SnackBar(content: Text('Session expired. Please search again.')),
          );
        }
        return false;
      }

      final dio = sl<Dio>();
      final legs = [
        {'index': _selectedIndex, 'amount': _selectedAmount, 'order_id': 1},
        for (final leg in widget.additionalLegs)
          {'index': leg.resultIndex, 'amount': leg.amount, 'order_id': leg.orderId},
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
            final isExpired = body.contains('1601') ||
                body.toLowerCase().contains('no record found');
            if (isExpired) {
              _showSessionExpiredDialog(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(body.isNotEmpty ? body : 'Could not confirm this fare. Please try again.')),
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
              const SnackBar(content: Text('Could not confirm this fare. Please try again.')),
            );
          }
          return false;
        }
        // Build a minimal AkGetSPricerEntity from the response so the fare
        // summary and review screen can render the total.
        _pricingTui = gspData['TUI']?.toString() ?? gspData['tui']?.toString() ?? '';
        _pricerData = AkGetSPricerModel.fromJson(gspData);
        _commitDone = true;
        if (mounted) setState(() => _committing = false);
        return true;
      } on DioException catch (e) {
        if (mounted) {
          setState(() => _committing = false);
          final body = e.response?.data?['error']?.toString() ?? e.message ?? '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body.isNotEmpty ? body : 'Could not confirm this fare. Please try again.')),
          );
        }
        return false;
      }
    }

    // ON/RT/RS/IM: standard SmartPricer → GetSPricer flow.
    _smartPricerBloc.add(LoadAkSmartPricerEvent(
      AkSmartPricerRequestEntity(
        searchTui: widget.tui,
        tripType: widget.tripType,
        trips: [
          AkSmartPricerTripRequestEntity(index: _selectedIndex, amount: _selectedAmount, orderId: 1),
          for (final leg in widget.additionalLegs)
            AkSmartPricerTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
        ],
        preview: false,
      ),
    ));

    final smartPricerState = await _smartPricerBloc.stream.firstWhere(
          (s) => s is AkSmartPricerLoaded || s is AkSmartPricerFailed,
    );
    if (smartPricerState is! AkSmartPricerLoaded) {
      if (mounted) {
        setState(() => _committing = false);
        final dioErr = (smartPricerState as AkSmartPricerFailed).error;
        final body = dioErr.response?.data?.toString() ?? dioErr.message ?? '';
        final isExpired = body.contains('1601') ||
            body.toLowerCase().contains('no record found');
        if (isExpired) {
          _showSessionExpiredDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not confirm this fare. Please try again.')),
          );
        }
      }
      return false;
    }
    _sessionId = smartPricerState.data.sessionId;

    _pricerBloc.add(LoadAkGetSPricerEvent(
      AkGetSPricerRequestEntity(tui: smartPricerState.data.tui, preview: false),
    ));

    final pricerState = await _pricerBloc.stream.firstWhere(
          (s) => s is AkGetSPricerLoaded || s is AkGetSPricerFailed,
    );
    if (pricerState is! AkGetSPricerLoaded) {
      if (mounted) {
        setState(() => _committing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not confirm this fare. Please try again.')),
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

  void _showSessionExpiredDialog(BuildContext context) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search Expired'),
        content: const Text(
          'This flight search has expired. Please go back and search again to get the latest prices.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Pop past detail popup back to the search results screen.
              // popUntil handles the case where the user is anywhere in the
              // booking stack (detail popup is always a direct push from results).
              Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Search Again'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmFareChange(BuildContext context, double newAmount) async {
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
    if (result is DataSuccess<AkAcceptFareChangeEntity> && result.data?.success == true) {
      return true;
    }
    // "No fare change is pending on this session" means Akbar's session has
    // already moved past the fare-change state (e.g. accepted in a prior call
    // or the session expired). The user has confirmed the new price, so treat
    // this as a benign no-op and continue.
    final dioErr = (result is DataFailed) ? result.error : null;
    final errMsg = (dioErr?.response?.data?.toString() ?? dioErr?.message ?? '').toLowerCase();
    if (errMsg.contains('no fare change is pending') || errMsg.contains('no fare change')) {
      return true;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not confirm the new fare. Please try again.')),
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
    final isDmIm = widget.tripType == 'DM' || widget.tripType == 'IM';
    final netAmt = isDmIm && _pricerData != null && _pricerData!.netAmount > 0
        ? _pricerData!.netAmount
        : data.netAmount;
    final totalPrice = '₹${netAmt.toStringAsFixed(0)}';
    Navigator.pop(context);

    // Build additional-leg routes from FlightInfo trips when available.
    // For DM/IM, fall back to widget.additionalLegs when data.trips only has
    // the first leg (happens when _dmImWidgetContent's minEntity was used).
    List<FlightRouteSegment> additionalLegRoutes;
    if (data.trips.length > 1) {
      additionalLegRoutes = data.trips
          .asMap()
          .entries
          .skip(1)
          .where((e) => e.value.journey.isNotEmpty && e.value.journey.first.segments.isNotEmpty)
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
          duration: _cleanDuration(legJourney.duration),
          airline: _marketingSegment(legFirstFlight.airline, fallback: legFirstFlight.airline),
          flightNo: "${_airlineCodeOf(legFirstFlight)} • ${legFirstFlight.flightNo}",
          price: '₹${legJourney.netFare.toStringAsFixed(0)}',
          stops: legJourney.stops,
          viaAirports: _viaAirportsOf(legSegments),
          isRefundable: legSegments.every((s) => s.flight.refundable.toUpperCase() == 'Y'),
          searchTui: widget.tui,
          pricingTui: _pricingTui,
          sessionId: _sessionId,
          amount: legJourney.netFare,
          akFareData: _pricerData,
          legIndex: tripIndex,
        );
      }).toList();
    } else if (isDmIm && widget.additionalLegs.isNotEmpty) {
      // FlightInfo didn't return multi-trip data — build from widget.additionalLegs
      // which always carries every selected leg's FlightEntity.
      additionalLegRoutes = widget.additionalLegs.asMap().entries.map((e) {
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
      fromCity: fromCity,  // NEW - pass city name
      toCity: toCity,
      price: totalPrice,
      traceId: widget.traceId,
      resultIndex: widget.resultIndex,
      departureTime: _formatTime(firstFlight.departureTime),
      arrivalTime: _formatTime(lastFlight.arrivalTime),
      departureDate: _formatDate(firstFlight.departureTime),
      duration: _cleanDuration(journey.duration),
      airline: _marketingSegment(firstFlight.airline, fallback: widget.airlineName),
      flightNo: "${_airlineCodeOf(firstFlight)} • ${firstFlight.flightNo}",
      stops: journey.stops,
      viaAirports: _viaAirportsOf(segments),
      isRefundable: isFullyRefundable,
      searchTui: widget.tui,
      pricingTui: _pricingTui,
      sessionId: _sessionId,
      amount: netAmt > 0 ? netAmt : widget.amount,
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
          childCount:
              widget.childCount > 0 ? widget.childCount : data.childCount,
          infantCount:
              widget.infantCount > 0 ? widget.infantCount : data.infantCount,
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

  String _marketingSegment(String value, {required String fallback}) {
    final parts = value.split('|').map((p) => p.trim()).toList();
    if (parts.length > 1 && parts[1].isNotEmpty) return parts[1];
    final firstNonEmpty = parts.firstWhere((p) => p.isNotEmpty, orElse: () => '');
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

      final parts = line.split('—').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
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
