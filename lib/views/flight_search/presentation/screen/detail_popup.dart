import 'dart:async';
import 'dart:math' as math;

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
import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/views/flight_search/domain/entities/flight_entity.dart' show FareFamilyIndexEntity;
import 'package:wander_nova/views/flight_search/domain/entities/fare_trip_type.dart';
import 'package:wander_nova/views/AKSmartPricer/domain/usecase/AKSmartPricer_usecase.dart';
import 'package:wander_nova/views/AKGetSPricer/domain/usecase/AKGetSPricer_usecase.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/seat_addons_screen.dart';

class FlightDetailsPopup extends StatefulWidget {
  // Needed to call FlightInfo: the search's tui and the chosen result's
  // Index + fare amount (as returned by GetExpSearch).
  final String tui;
  final String resultIndex;
  final double amount;

  // Shown immediately while FlightInfo loads, before the real segment/fare
  // data is available.
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

  /// Number of travellers — forwarded to booking → SSR for seat selection.
  final int travellerCount;

  /// Sibling fare-class variants of this same physical flight (Saver/Flexi/
  /// SME/...), preserved from GetExpSearch by flight_search_screen.dart's
  /// `_cheapestPerFlight` instead of being discarded. Null/empty when the
  /// flight only has one fare — the "Choose Your Fare" section then just
  /// shows the single (tapped) fare.
  final List<FareFamilyIndexEntity>? fareFamilyOptions;

  /// Wire fareType ('ON'/'RT'/'RS'/'DM'/'IM'). Defaults to 'ON' so every
  /// existing one-way call site keeps sending exactly what it does today.
  final String tripType;

  /// Additional legs beyond the one described by the fields above (which is
  /// always leg 1 / orderId 1) — the return leg for RT/RS, or legs 2..N for
  /// Multi City. Empty for 'ON', where there is only ever one leg. This
  /// popup is only ever opened once per search — for 'ON' with the tapped
  /// flight, or for RT/RS/IM/DM once every column has a pick — so it always
  /// runs the real booking chain; there's no separate "preview" mode.
  final List<FlightLegSelection> additionalLegs;

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
    this.fareFamilyOptions,
    this.tripType = 'ON',
    this.additionalLegs = const [],
  });

  static void show(
      BuildContext context, {
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
        List<FareFamilyIndexEntity>? fareFamilyOptions,
        String tripType = 'ON',
        List<FlightLegSelection> additionalLegs = const [],
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
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
        fareFamilyOptions: fareFamilyOptions,
        tripType: tripType,
        additionalLegs: additionalLegs,
      ),
    );
  }

  @override
  State<FlightDetailsPopup> createState() => _FlightDetailsPopupState();
}

class _FlightDetailsPopupState extends State<FlightDetailsPopup> {
  late final AkFlightInfoBloc _bloc;
  late final AkSmartPricerBloc _smartPricerBloc;
  late final AkGetSPricerBloc _pricerBloc;
  late final AkFareRuleBloc _fareRuleBloc;

  // Guards against re-firing SmartPricer/GetSPricer on every rebuild once
  // their preceding step has loaded — each should only be requested once
  // per sheet open.
  bool _smartPricerRequested = false;
  bool _pricerRequested = false;

  // Captured off SmartPricer/GetSPricer's own responses — threaded into
  // FlightRouteSegment for booking_screen.dart's Akbar CreateItinerary/
  // StartPay chain. sessionId is the one identifier that flows through
  // the entire rest of the booking (AcceptFareChange, GetTravelCheckList,
  // CreateItinerary, StartPay, RetrieveBooking, and the CCAvenue payment
  // reference_id).
  String? _sessionId;
  String? _pricingTui;
  AkGetSPricerEntity? _pricerData;
  bool _fareChangeAccepted = false;

  // Fare-family selector. Sourced from widget.fareFamilyOptions (GetExpSearch's
  // sibling Index/amount/refundable, preserved by flight_search_screen.dart)
  // rather than re-fetched — that data is already known before this screen
  // even opens. `_selectedIndex`/`_selectedAmount` track which one is
  // currently being previewed; they start at the originally tapped fare.
  late String _selectedIndex = widget.resultIndex;
  late double _selectedAmount = widget.amount;
  bool _switchingFare = false;
  // True only while the final, non-preview commit (SmartPricer+GetSPricer
  // with preview:false) is in flight, right after Book Now is tapped.
  bool _committing = false;

  List<FareFamilyIndexEntity> get _fareOptions {
    final options = widget.fareFamilyOptions;
    if (options != null && options.isNotEmpty) return options;
    return [FareFamilyIndexEntity(index: widget.resultIndex, amount: widget.amount, refundable: true)];
  }

  @override
  void initState() {
    super.initState();
    _bloc = sl<AkFlightInfoBloc>();
    _smartPricerBloc = sl<AkSmartPricerBloc>();
    _pricerBloc = sl<AkGetSPricerBloc>();
    _fareRuleBloc = sl<AkFareRuleBloc>();
    _load();
    _loadFareRule();
  }

  /// Change-fee/cancellation-fee text for the Paytm-style fare details card.
  /// Independent of the FlightInfo -> SmartPricer -> GetSPricer chain — only
  /// needs the original search tui + resultIndex + amount, same as the
  /// existing AkFareRulePopup usage elsewhere in the booking flow. FareRule
  /// has no preview flag — the real backend view never writes anything to
  /// the session, so it's always safe to call for any fare being browsed.
  void _loadFareRule() {
    _fareRuleBloc.add(LoadAkFareRuleEvent(
      AkFareRuleRequestEntity(
        tui: widget.tui,
        trips: [
          AkFareRuleTripRequestEntity(index: _selectedIndex, amount: _selectedAmount, orderId: 1),
          for (final leg in widget.additionalLegs)
            AkFareRuleTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
        ],
      ),
    ));
  }

  void _load() {
    _bloc.add(LoadAkFlightInfoEvent(
      AkFlightInfoRequestEntity(
        tui: widget.tui,
        tripType: widget.tripType,
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

  /// SmartPricer initiates re-pricing and hands back a fresh (pricing) tui —
  /// called automatically once FlightInfo resolves. Must be called with the
  /// original ExpressSearch/GetExpSearch search tui (widget.tui) — NOT
  /// FlightInfo's own returned tui; passing it here gets Akbar's "No Record
  /// found". `preview` defaults true here: this auto-chain fires the moment
  /// the sheet opens (or the user switches fares) purely to show live
  /// price/baggage — the real backend docs call this exact case "a flight
  /// the user is only peeking at", and it must not overwrite
  /// session.pricing_tui. Only the Book Now commit step passes preview:false.
  void _loadSmartPricer(String searchTui, {bool preview = true}) {
    _smartPricerRequested = true;
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
      ),
    ));
  }

  /// GetSPricer re-confirms live fare/flight details using the tui
  /// SmartPricer just returned — called automatically once SmartPricer
  /// resolves. (SmartPricer's data may be served from cache; GetSPricer's
  /// tui must be used here, not FlightInfo's, to get live fare data.) Same
  /// preview semantics as SmartPricer — see [_loadSmartPricer].
  void _loadPricer(String smartPricerTui, {bool preview = true}) {
    _pricerRequested = true;
    _pricerBloc.add(LoadAkGetSPricerEvent(
      AkGetSPricerRequestEntity(tui: smartPricerTui, preview: preview),
    ));
  }

  /// Switches which fare family (real GetExpSearch Index, from
  /// widget.fareFamilyOptions) is currently being browsed. Re-runs the whole
  /// FlightInfo -> SmartPricer(preview) -> GetSPricer(preview) -> FareRule
  /// chain for that index — a genuinely different itinerary needs its own
  /// FlightInfo, not just a re-price — and stays in preview mode: nothing
  /// here commits session.pricing_tui, so switching back and forth while
  /// browsing is free. Book Now (see [_confirmAndBookNow]) is what commits.
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
    });
    _load();
    _loadFareRule();
  }

  @override
  void dispose() {
    _bloc.close();
    _smartPricerBloc.close();
    _pricerBloc.close();
    _fareRuleBloc.close();
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
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AkFlightInfoBloc, AkFlightInfoState>(
            listener: (context, state) {
              if (state is AkFlightInfoLoaded && !_smartPricerRequested) {
                _loadSmartPricer(widget.tui);
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
              } else if (state is AkSmartPricerFailed && _switchingFare) {
                _switchingFare = false;
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
        ],
        child: Padding(
          padding: EdgeInsets.only(
            left: context.w(10),
            right: context.w(10),
            bottom: MediaQuery.of(context).viewInsets.bottom + context.h(8),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: context.screenHeight * 0.88),
            decoration: BoxDecoration(
              color: const Color(0xffF4F7FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(22))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: context.w(22),
                  offset: Offset(0, -context.h(6)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(22))),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(14),
                    context.h(8),
                    context.w(14),
                    context.h(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: context.w(36),
                        height: context.h(3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xffCBD5E1),
                          borderRadius: BorderRadius.circular(context.r(4)),
                        ),
                      ),
                      SizedBox(height: context.h(10)),
                      _header(context),
                      if (widget.additionalLegs.isNotEmpty) ...[
                        SizedBox(height: context.h(8)),
                        _additionalLegsSummary(context),
                      ],
                      SizedBox(height: context.h(12)),
                      // Rendered here, outside the FlightInfo BlocBuilder
                      // below, so the fare picker (and its own inline
                      // "Re-pricing…" indicator) stays visible and tappable
                      // while switching fares reloads the ticket/itinerary
                      // section beneath it, instead of the whole sheet
                      // blanking out to a single spinner.
                      if (_fareOptions.length > 1) ...[
                        _verticalFareCards(context, _fareOptions),
                        SizedBox(height: context.h(10)),
                      ],
                      BlocBuilder<AkFlightInfoBloc, AkFlightInfoState>(
                        builder: (context, flightInfoState) {
                          if (flightInfoState is AkFlightInfoFailed) {
                            return _errorState(
                              context,
                              flightInfoState.error.message ?? 'Failed to load flight details',
                            );
                          }
                          if (flightInfoState is AkFlightInfoLoaded) {
                            // GetSPricer re-confirms price/fare details using
                            // FlightInfo's tui. While it's still in flight
                            // (or if it fails), keep showing FlightInfo's own
                            // data rather than blocking on a second spinner —
                            // the numbers below just refine once it resolves.
                            return BlocBuilder<AkGetSPricerBloc, AkGetSPricerState>(
                              builder: (context, pricerState) {
                                if (pricerState is AkGetSPricerLoaded) {
                                  final merged = _mergeWithPricer(
                                    flightInfoState.data,
                                    pricerState.data,
                                  );
                                  return _loadedContent(
                                    context,
                                    merged,
                                    includedBaggage: pricerState.data.includedBaggage,
                                    fareChanged: pricerState.data.fareChanged,
                                  );
                                }
                                return _loadedContent(context, flightInfoState.data);
                              },
                            );
                          }
                          return _loadingState(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header (shown immediately, before FlightInfo resolves)
  // ---------------------------------------------------------------------------
  Widget _header(BuildContext context) {
    return Row(
      children: [
        _airlineBadge(context, widget.airlineCode, widget.airlineName, size: context.w(32)),
        SizedBox(width: context.w(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.airlineName,
                style: TextStyle(
                  color: const Color(0xff07163B),
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.h(1)),
              Text(
                'Flight ${widget.flightNumber}',
                style: TextStyle(
                  color: const Color(0xff8D95B3),
                  fontSize: context.fs(10),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(context.r(16)),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: context.w(28),
            height: context.w(28),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.close, color: const Color(0xff4B5563), size: context.w(15)),
          ),
        ),
      ],
    );
  }

  /// Compact summary of every leg beyond the first (return leg for RT/RS,
  /// legs 2..N for Multi City) — the price/fare breakdown below already
  /// covers all of them combined (FlightInfo/SmartPricer/GetSPricer were
  /// sent every leg's index/orderId), this just makes clear to the user
  /// which flights that combined total actually includes.
  Widget _additionalLegsSummary(BuildContext context) {
    return Column(
      children: widget.additionalLegs.map((leg) {
        final f = leg.flight;
        return Container(
          margin: EdgeInsets.only(bottom: context.h(6)),
          padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(8)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(10)),
            border: Border.all(color: const Color(0xffE9EDF6)),
          ),
          child: Row(
            children: [
              _airlineBadge(context, f.airlineCode ?? '--', f.airlineName ?? 'Airline', size: context.w(26)),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${f.originName ?? f.origin ?? ''} → ${f.destinationName ?? f.destination ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xff07163B),
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${f.airlineName ?? 'Airline'} · ${f.flightNumber ?? ''}',
                      style: TextStyle(
                        color: const Color(0xff8D95B3),
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading / error states
  // ---------------------------------------------------------------------------
  Widget _loadingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(40)),
      child: Column(
        children: [
          SizedBox(
            width: context.w(28),
            height: context.w(28),
            child: const CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(height: context.h(12)),
          Text(
            'Fetching latest fare & flight details...',
            style: TextStyle(
              color: const Color(0xff6B7280),
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(28)),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: context.w(30)),
          SizedBox(height: context.h(10)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff4B5563),
              fontSize: context.fs(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.h(12)),
          TextButton(
            onPressed: _load,
            child: Text(
              'Retry',
              style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loaded content — everything below is built from the real FlightInfo
  // response, not placeholders.
  // ---------------------------------------------------------------------------
  Widget _loadedContent(
      BuildContext context,
      AkFlightInfoEntity data, {
        Map<String, Map<String, AkGetSPricerBaggageEntity>> includedBaggage = const {},
        bool fareChanged = false,
      }) {
    // Exactly one journey is ever fetched now — FlightInfo/SmartPricer/
    // GetSPricer each take exactly one `trips: [{index, amount, order_id}]`
    // and return exactly one journey for it (confirmed against the real
    // backend). No need to search a list by order_id anymore.
    final journey = data.trips.isNotEmpty && data.trips.first.journey.isNotEmpty
        ? data.trips.first.journey.first
        : null;

    if (journey == null || journey.segments.isEmpty) {
      return _errorState(context, 'No flight details available for this fare.');
    }

    final segments = journey.segments;
    final stops = segments.length - 1;
    final firstFlight = segments.first.flight;
    final lastFlight = segments.last.flight;
    final isFullyRefundable =
    segments.every((s) => s.flight.refundable.toUpperCase() == 'Y');
    final minSeats = segments
        .map((s) => s.flight.seats)
        .fold<int>(1 << 30, (m, s) => s < m ? s : m);

    return Column(
      children: [
        if (fareChanged) ...[
          _fareChangedBanner(context),
          SizedBox(height: context.h(10)),
        ],
        _itinerary(context, segments, includedBaggage),
        SizedBox(height: context.h(10)),
        _amenities(context, isFullyRefundable, minSeats),
        SizedBox(height: context.h(8)),
        _features(context),
        SizedBox(height: context.h(10)),
        _bottomBar(context, data, journey, firstFlight, lastFlight, isFullyRefundable, fareChanged),
      ],
    );
  }

  Widget _fareChangedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(8)),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7E6),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: const Color(0xffFACC15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xffB45309), size: context.w(14)),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Text(
              'The fare for this flight has changed — prices below reflect the latest fare.',
              style: TextStyle(
                color: const Color(0xffB45309),
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Merges GetSPricer's re-confirmed data into an [AkFlightInfoEntity] so
  /// it flows through the same rendering as FlightInfo's own data — no
  /// separate render path, just fresher numbers/segments once available.
  ///
  /// FlightInfo's response never carries a real session_id — only
  /// SmartPricer's does — so this prefers the session_id captured off
  /// SmartPricer's own response over FlightInfo's (usually empty) one.
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

  AkGetSPricerBaggageEntity? _baggageFor(
      Map<String, Map<String, AkGetSPricerBaggageEntity>> includedBaggage,
      int fuid,
      ) {
    final byPtc = includedBaggage[fuid.toString()];
    if (byPtc == null || byPtc.isEmpty) return null;
    return byPtc['ADT'] ?? byPtc.values.first;
  }

  // ---------------------------------------------------------------------------
  // Itinerary — one card per real flight segment, with a layover connector
  // between legs for connecting flights.
  // ---------------------------------------------------------------------------
  Widget _itinerary(
      BuildContext context,
      List<AkFlightInfoSegmentEntity> segments,
      Map<String, Map<String, AkGetSPricerBaggageEntity>> includedBaggage,
      ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xffE6ECFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flight Itinerary',
            style: TextStyle(
              color: const Color(0xff07163B),
              fontSize: context.fs(12),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: context.h(10)),
          for (var i = 0; i < segments.length; i++) ...[
            _segmentRow(
              context,
              segments[i].flight,
              _baggageFor(includedBaggage, segments[i].flight.fuid),
            ),
            if (i < segments.length - 1)
              _layoverRow(context, segments[i].flight, segments[i + 1].flight),
          ],
        ],
      ),
    );
  }

  Widget _segmentRow(
      BuildContext context,
      AkFlightInfoFlightEntity flight,
      AkGetSPricerBaggageEntity? baggage,
      ) {
    final code = _airlineCodeOf(flight);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _airlineBadge(context, code, flight.airline, size: context.w(26)),
        SizedBox(width: context.w(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_marketingSegment(flight.airline, fallback: code)} · $code${flight.flightNo}',
                style: TextStyle(
                  color: const Color(0xff07163B),
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: context.h(4)),
              Row(
                children: [
                  Expanded(
                    child: _segmentEndpoint(
                      context,
                      time: _formatApiTime(flight.departureTime),
                      code: flight.departureCode,
                      name: _lastSegment(flight.depAirportName),
                      terminal: flight.departureTerminal,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(6)),
                    child: Icon(Icons.arrow_forward, size: context.w(13), color: const Color(0xffA0A6C2)),
                  ),
                  Expanded(
                    child: _segmentEndpoint(
                      context,
                      time: _formatApiTime(flight.arrivalTime),
                      code: flight.arrivalCode,
                      name: _lastSegment(flight.arrAirportName),
                      terminal: flight.arrivalTerminal,
                      alignRight: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(6)),
              Wrap(
                spacing: context.w(6),
                runSpacing: context.h(4),
                children: [
                  _tag(context, _cleanDuration(flight.duration)),
                  if (flight.cabin.isNotEmpty) _tag(context, flight.cabin == 'E' ? 'Economy' : flight.cabin),
                  if (flight.aircraft.isNotEmpty) _tag(context, flight.aircraft),
                  _tag(context, flight.refundable.toUpperCase() == 'Y' ? 'Refundable' : 'Non-refundable'),
                  if (baggage != null && baggage.checkin.isNotEmpty)
                    _tag(context, '${baggage.checkin} check-in'),
                  if (baggage != null && baggage.cabin.isNotEmpty)
                    _tag(context, '${baggage.cabin} cabin'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segmentEndpoint(
      BuildContext context, {
        required String time,
        required String code,
        required String name,
        required String terminal,
        bool alignRight = false,
      }) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            color: const Color(0xff3D3F4A),
            fontSize: context.fs(14),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          terminal.isNotEmpty ? '$code · T$terminal' : code,
          style: TextStyle(
            color: const Color(0xffA0A6C2),
            fontSize: context.fs(10),
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xff9AA2BF),
            fontSize: context.fs(9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _tag(BuildContext context, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(7), vertical: context.h(2)),
      decoration: BoxDecoration(
        color: const Color(0xffF3F6FF),
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xff5F86FF),
          fontSize: context.fs(9),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _layoverRow(
      BuildContext context,
      AkFlightInfoFlightEntity arriving,
      AkFlightInfoFlightEntity departing,
      ) {
    final layover = _layoverLabel(arriving.arrivalTime, departing.departureTime);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(10)),
      child: Row(
        children: [
          SizedBox(width: context.w(26), child: Icon(Icons.schedule, size: context.w(13), color: const Color(0xffF59E0B))),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              layover != null
                  ? 'Change planes at ${arriving.arrivalCode} · $layover layover'
                  : 'Change of flight at ${arriving.arrivalCode}',
              style: TextStyle(
                color: const Color(0xffB45309),
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VERTICAL FARE CARDS - REDESIGNED: Horizontal scrollable row
  // ---------------------------------------------------------------------------
  Widget _verticalFareCards(BuildContext context, List<FareFamilyIndexEntity> options) {
    final sorted = [...options]..sort((a, b) => a.amount.compareTo(b.amount));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Choose Your Fare',
              style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w800, color: const Color(0xff07163B)),
            ),
            if (_switchingFare) ...[
              SizedBox(width: context.w(8)),
              SizedBox(
                width: context.w(13),
                height: context.w(13),
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: context.w(6)),
              Text(
                'Loading fare…',
                style: TextStyle(fontSize: context.fs(10.5), color: const Color(0xff6B7280), fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        SizedBox(height: context.h(10)),
        // Horizontal scrollable row of fare cards
        SizedBox(
          height: context.h(360), // Fixed height for horizontal scroll
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            separatorBuilder: (_, __) => SizedBox(width: context.w(10)),
            itemBuilder: (_, i) => SizedBox(
              width: context.w(260), // Fixed width for each card
              child: _verticalFareCard(context, sorted[i], i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _verticalFareCard(BuildContext context, FareFamilyIndexEntity option, int rank) {
    final selected = option.index == _selectedIndex;
    // Real-time detail is only available for the fare currently being
    // previewed (SmartPricer/GetSPricer only ever price one index at a
    // time) — other cards show what GetExpSearch already told us
    // (price, refundable) plus a "select to view" placeholder for the rest.
    final label = selected && (_pricerData?.fareType.isNotEmpty ?? false)
        ? _pricerData!.fareType
        : (rank == 0 ? 'Cheapest Fare' : 'Fare Option ${rank + 1}');
    final hasLiveDiscount = selected && _pricerData != null && _pricerData!.grossAmount > _pricerData!.netAmount;
    final displayAmount = selected && _pricerData != null ? _pricerData!.netAmount : option.amount;

    String checkinBaggageText = 'Select fare to view';
    String handBaggageText = 'Select fare to view';
    if (selected && _pricerData != null) {
      final firstFuid = _pricerData!.trips.isNotEmpty && _pricerData!.trips.first.journey.isNotEmpty
          ? (_pricerData!.trips.first.journey.first.segments.isNotEmpty
          ? _pricerData!.trips.first.journey.first.segments.first.flight.fuid
          : null)
          : null;
      final baggage = firstFuid != null ? _baggageFor(_pricerData!.includedBaggage, firstFuid) : null;
      checkinBaggageText = baggage != null && baggage.checkin.isNotEmpty ? baggage.checkin : 'As per airline policy';
      handBaggageText = baggage != null && baggage.cabin.isNotEmpty ? baggage.cabin : 'As per airline policy';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffF6F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(
          color: selected ? const Color(0xff1663F7) : const Color(0xffE6ECFF),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: const Color(0xff1663F7).withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 6))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 0) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
              decoration: BoxDecoration(
                color: const Color(0xff07163B),
                borderRadius: BorderRadius.circular(context.r(20)),
              ),
              child: Text(
                'Lowest price',
                style: TextStyle(fontSize: context.fs(8), fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            SizedBox(height: context.h(6)),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w800, color: const Color(0xff07163B)),
                    ),
                    SizedBox(height: context.h(4)),
                    Row(
                      children: [
                        if (hasLiveDiscount) ...[
                          Text(
                            '₹${_pricerData!.grossAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: context.fs(10),
                              color: const Color(0xff9CA3AF),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(width: context.w(6)),
                        ],
                        Text(
                          '₹${displayAmount.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w800, color: const Color(0xff07163B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
                  decoration: BoxDecoration(color: const Color(0xff1663F7), borderRadius: BorderRadius.circular(context.r(20))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: context.w(10), color: Colors.white),
                      SizedBox(width: context.w(3)),
                      Text('Selected', style: TextStyle(fontSize: context.fs(8), fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: context.h(8)),
          _thinDivider(context),
          _fareDetailRowCompact(context, 'Seat', 'Chosen on next step'),
          _thinDivider(context),
          _fareDetailRowCompact(context, 'Meal', 'Chosen on next step'),
          _thinDivider(context),
          if (selected)
            BlocBuilder<AkFareRuleBloc, AkFareRuleState>(
              bloc: _fareRuleBloc,
              builder: (context, state) {
                final loading = state is AkFareRuleLoading || state is AkFareRuleInitial;
                final texts = state is AkFareRuleLoaded ? state.data.ruleTexts : const <String>[];
                final changeFee = _extractFeeText(texts, const ['change', 'reissue']);
                final cancelFee = _extractFeeText(texts, const ['cancellation', 'cancel']);
                return Column(
                  children: [
                    _fareDetailRowCompact(
                      context,
                      'Change Fee',
                      loading ? 'Loading…' : (changeFee ?? 'View rules'),
                      isLink: !loading && changeFee == null,
                      onTap: !loading && changeFee == null ? () => _openFareRules(context) : null,
                    ),
                    _thinDivider(context),
                    _fareDetailRowCompact(
                      context,
                      'Cancellation Fee',
                      loading ? 'Loading…' : (cancelFee ?? 'View rules'),
                      isLink: !loading && cancelFee == null,
                      onTap: !loading && cancelFee == null ? () => _openFareRules(context) : null,
                    ),
                  ],
                );
              },
            )
          else ...[
            _fareDetailRowCompact(context, 'Change Fee', 'Select to view'),
            _thinDivider(context),
            _fareDetailRowCompact(context, 'Cancellation Fee', 'Select to view'),
          ],
          _thinDivider(context),
          _fareDetailRowCompact(context, 'Check-in baggage', checkinBaggageText),
          _thinDivider(context),
          _fareDetailRowCompact(context, 'Hand baggage', handBaggageText),
          _thinDivider(context),
          _fareDetailRowCompact(
            context,
            'Refund',
            option.refundable ? 'Refundable' : 'Non-refundable',
            valueColor: option.refundable ? const Color(0xff16A34A) : const Color(0xffB42318),
          ),
          if (!selected) ...[
            SizedBox(height: context.h(10)),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _switchingFare ? null : () => _selectFare(option),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xff1663F7)),
                  padding: EdgeInsets.symmetric(vertical: context.h(8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(8))),
                ),
                child: Text(
                  'Select',
                  style: TextStyle(color: const Color(0xff1663F7), fontWeight: FontWeight.w800, fontSize: context.fs(11)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Compact fare detail row for horizontal cards
  Widget _fareDetailRowCompact(
      BuildContext context,
      String label,
      String value, {
        Color? valueColor,
        bool isLink = false,
        VoidCallback? onTap,
      }) {
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.fs(9.5),
              color: const Color(0xff7C849F),
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(9.5),
                fontWeight: FontWeight.w700,
                color: isLink ? const Color(0xff1663F7) : (valueColor ?? const Color(0xff07163B)),
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
    return onTap != null
        ? InkWell(borderRadius: BorderRadius.circular(context.r(6)), onTap: onTap, child: row)
        : row;
  }

  Widget _thinDivider(BuildContext context) => Divider(height: context.h(1), thickness: 1, color: const Color(0xffF0F2F8));

  /// Best-effort extraction of a fee value from FareRule's free-text rule
  /// lines (the API doc doesn't pin down a structured fee field — see
  /// AKFareRule_model.dart's own comment on this). Prefers a currency
  /// amount; when a line matches the keyword but carries no amount (real
  /// responses can say e.g. "Non Refundable" instead of a ₹ figure), falls
  /// back to that short verdict text. Returns null only when no line
  /// matches any keyword at all, so the caller can fall back to a
  /// "View fare rules" link instead of showing a wrong or missing value.
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

  void _openFareRules(BuildContext context) {
    // GetSPricer's confirmed total once available, else the currently
    // selected fare's own (search-time) amount.
    final amount = (_pricerData != null && _pricerData!.netAmount > 0) ? _pricerData!.netAmount : _selectedAmount;
    AkFareRulePopup.show(
      context,
      searchTui: widget.tui,
      resultIndex: _selectedIndex,
      amount: amount,
    );
  }

  Widget _amenities(BuildContext context, bool isFullyRefundable, int seatsLeft) {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            context,
            icon: Icons.event_seat_outlined,
            iconColor: const Color(0xff9B5DE5),
            title: 'Seats Left',
            subtitle: seatsLeft > 0 ? '$seatsLeft seats at this fare' : 'Limited availability',
          ),
        ),
        SizedBox(width: context.w(8)),
        Expanded(
          child: _infoCard(
            context,
            icon: isFullyRefundable ? Icons.verified_outlined : Icons.block_outlined,
            iconColor: isFullyRefundable ? const Color(0xff16A34A) : const Color(0xffB42318),
            title: 'Flexibility',
            subtitle: isFullyRefundable ? 'Refundable fare' : 'Non-refundable fare',
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
      }) {
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xffE6ECFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.w(26),
            height: context.w(26),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: context.w(14)),
          ),
          SizedBox(width: context.w(7)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xff07163B),
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xff7C849F),
                    fontSize: context.fs(9),
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _features(BuildContext context) {
    final items = [
      (Icons.lock_outline, 'Trusted Booking', '100% Secure'),
      (Icons.headphones, '24/7 Support', "We're here to help"),
      (Icons.sync_alt, 'Easy Changes', 'Hassle-free'),
      (Icons.verified_outlined, 'Best Price', 'Best deals'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: const Color(0xffFFFDF2),
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xffFDE68A)),
      ),
      child: Wrap(
        spacing: context.w(12),
        runSpacing: context.h(8),
        children: items
            .map(
              (item) => SizedBox(
            width: context.w(130),
            child: Row(
              children: [
                Icon(item.$1, color: const Color(0xffF59E0B), size: context.w(13)),
                SizedBox(width: context.w(5)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: const Color(0xff07163B),
                          fontSize: context.fs(9),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        item.$3,
                        style: TextStyle(
                          color: const Color(0xff7C849F),
                          fontSize: context.fs(8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _bottomBar(
      BuildContext context,
      AkFlightInfoEntity data,
      AkFlightInfoJourneyEntity journey,
      AkFlightInfoFlightEntity firstFlight,
      AkFlightInfoFlightEntity lastFlight,
      bool isFullyRefundable,
      bool fareChanged,
      ) {
    final bookingReady = _sessionId != null && _pricingTui != null && !_switchingFare && !_committing;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                isFullyRefundable ? Icons.verified_user_outlined : Icons.info_outline,
                color: isFullyRefundable ? const Color(0xff16A34A) : const Color(0xff9CA3AF),
                size: context.w(15),
              ),
              SizedBox(width: context.w(6)),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isFullyRefundable ? 'Free cancellation ' : 'Non-refundable fare ',
                        style: TextStyle(
                          color: isFullyRefundable ? const Color(0xff16A34A) : const Color(0xff6B7280),
                          fontWeight: FontWeight.w800,
                          fontSize: context.fs(9),
                        ),
                      ),
                      TextSpan(
                        text: 'as per airline policy',
                        style: TextStyle(
                          color: const Color(0xff4B5563),
                          fontWeight: FontWeight.w500,
                          fontSize: context.fs(9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(10)),
        SizedBox(
          height: context.h(42),
          child: ElevatedButton(
            onPressed: bookingReady
                ? () => _handleBookNow(
              context,
              data,
              journey,
              firstFlight,
              lastFlight,
              isFullyRefundable,
              fareChanged,
            )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1663F7),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xffA0A6C2),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: context.w(18)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
            ),
            child: bookingReady
                ? Text(
              'Book Now',
              style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w800),
            )
                : SizedBox(
              width: context.w(16),
              height: context.w(16),
              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Gates "Book Now" on the fare-change consent flow: if GetSPricer flagged
  /// `fareChanged`, the doc requires showing the new fare, getting explicit
  /// consent, and calling AcceptFareChange before CreateItinerary is allowed
  /// to run later in the booking screen.
  Future<void> _handleBookNow(
      BuildContext context,
      AkFlightInfoEntity data,
      AkFlightInfoJourneyEntity journey,
      AkFlightInfoFlightEntity firstFlight,
      AkFlightInfoFlightEntity lastFlight,
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

    _bookNow(context, data, journey, firstFlight, lastFlight, isFullyRefundable);
  }

  /// Final, non-preview SmartPricer -> GetSPricer commit. Every SmartPricer/
  /// GetSPricer call made while the user was browsing this sheet (initial
  /// load, fare switches) runs with `preview: true`, which by design never
  /// writes `session.pricing_tui` server-side (see [_loadSmartPricer]) — so
  /// without this step, CreateItinerary (called next, from the booking
  /// screen) 400s with "This session has not been priced yet". This re-runs
  /// the same chain with `preview: false` right before navigating on, so the
  /// session is actually priced by the time booking details are submitted.
  Future<bool> _commitPricing() async {
    setState(() => _committing = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not confirm this fare. Please try again.')),
        );
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

    if (mounted) setState(() => _committing = false);
    return true;
  }

  Future<bool> _confirmFareChange(BuildContext context, double newAmount) async {
    final wantsToContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fare Updated'),
        content: Text(
          'The price for this flight has changed to ${_formatAmount(newAmount)}. '
              'Do you want to continue with the new fare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Accept & Continue'),
          ),
        ],
      ),
    );
    if (wantsToContinue != true || _sessionId == null) return false;

    final result = await sl<AkAcceptFareChangeUseCase>().call(
      AkAcceptFareChangeRequestEntity(sessionId: _sessionId!),
    );
    if (result is DataSuccess<AkAcceptFareChangeEntity> && result.data?.success == true) {
      return true;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not confirm the new fare. Please try again.')),
      );
    }
    return false;
  }

  Widget _airlineBadge(BuildContext context, String code, String name, {required double size}) {
    final logoCode = code.trim().toUpperCase();
    final initials = _displayAirlineCode(logoCode.isNotEmpty ? logoCode : name);

    Widget initialsTile() => Container(
      color: _airlineColor(initials),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontSize: context.fs(9), fontWeight: FontWeight.w900),
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
      child: logoCode.isEmpty
          ? initialsTile()
          : Padding(
        padding: EdgeInsets.all(context.w(3)),
        child: CachedNetworkImage(
          imageUrl: 'https://images.kiwi.com/airlines/64/$logoCode.png',
          fit: BoxFit.contain,
          placeholder: (_, __) => initialsTile(),
          errorWidget: (_, __, ___) => initialsTile(),
        ),
      ),
    );
  }

  void _bookNow(
      BuildContext context,
      AkFlightInfoEntity data,
      AkFlightInfoJourneyEntity journey,
      AkFlightInfoFlightEntity firstFlight,
      AkFlightInfoFlightEntity lastFlight,
      bool isFullyRefundable,
      ) {
    final totalPrice = _formatAmount(data.netAmount);
    Navigator.pop(context);

    // Legs beyond the first (return leg for RT/RS, legs 2..N for Multi
    // City) — each is its own confirmed AkFlightInfo trip/journey, since
    // FlightInfo/SmartPricer/GetSPricer were sent every leg's index/orderId,
    // not just the first.
    final additionalLegRoutes = data.trips.length > 1
        ? data.trips
            .sublist(1)
            .where((trip) => trip.journey.isNotEmpty && trip.journey.first.segments.isNotEmpty)
            .map((trip) {
              final legJourney = trip.journey.first;
              final legSegments = legJourney.segments;
              final legFirstFlight = legSegments.first.flight;
              final legLastFlight = legSegments.last.flight;
              return FlightRouteSegment(
                from: legFirstFlight.departureCode,
                to: legLastFlight.arrivalCode,
                departureTime: _formatApiTime(legFirstFlight.departureTime),
                arrivalTime: _formatApiTime(legLastFlight.arrivalTime),
                departureDate: _formatApiDate(legFirstFlight.departureTime),
                duration: _cleanDuration(legJourney.duration),
                airline: _marketingSegment(legFirstFlight.airline, fallback: legFirstFlight.airline),
                flightNo: "${_airlineCodeOf(legFirstFlight)} • ${legFirstFlight.flightNo}",
                price: _formatAmount(legJourney.netFare),
                stops: legJourney.stops,
                viaAirports: _viaAirportsOf(legSegments),
                isRefundable: legSegments.every((s) => s.flight.refundable.toUpperCase() == 'Y'),
                searchTui: widget.tui,
                pricingTui: _pricingTui,
                sessionId: _sessionId,
                amount: legJourney.netFare,
              );
            })
            .toList()
        : const <FlightRouteSegment>[];

    final route = FlightRouteSegment(
      from: firstFlight.departureCode,
      to: lastFlight.arrivalCode,
      price: totalPrice,
      traceId: widget.traceId,
      resultIndex: widget.resultIndex,
      departureTime: _formatApiTime(firstFlight.departureTime),
      arrivalTime: _formatApiTime(lastFlight.arrivalTime),
      departureDate: _formatApiDate(firstFlight.departureTime),
      duration: _cleanDuration(journey.duration),
      airline: _marketingSegment(firstFlight.airline, fallback: widget.airlineName),
      flightNo: "${_airlineCodeOf(firstFlight)} • ${firstFlight.flightNo}",
      stops: journey.stops,
      viaAirports: _viaAirportsOf(journey.segments),
      isRefundable: isFullyRefundable,
      searchTui: widget.tui,
      pricingTui: _pricingTui,
      sessionId: _sessionId,
      // The currently selected fare family's confirmed amount, not
      // necessarily widget.amount (the originally tapped card) — the user
      // may have switched fares via the selector above.
      amount: data.netAmount > 0 ? data.netAmount : widget.amount,
      akFareData: _pricerData,
    );

    final pricer = _pricerData;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatAddonsScreen(
          route: route,
          totalPrice: totalPrice,
          traceId: widget.traceId,
          resultIndex: widget.resultIndex,
          price: totalPrice,
          travellerCount: widget.travellerCount,
          adultCount: pricer?.adultCount ?? 0,
          childCount: pricer?.childCount ?? 0,
          infantCount: pricer?.infantCount ?? 0,
          additionalLegs: additionalLegRoutes,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  /// Prefers the real marketing carrier code (MAC) over VAC, matching the
  /// convention used for the search results list.
  String _airlineCodeOf(AkFlightInfoFlightEntity flight) =>
      flight.mac.isNotEmpty ? flight.mac : flight.vac;

  /// The connecting airport(s) between segments of a multi-segment (stopover)
  /// journey — every segment's arrival code except the last, since the last
  /// segment's arrival is the journey's final destination, not a stop.
  List<String> _viaAirportsOf(List<AkFlightInfoSegmentEntity> segments) {
    if (segments.length <= 1) return const [];
    return segments
        .sublist(0, segments.length - 1)
        .map((s) => s.flight.arrivalCode)
        .toList();
  }

  /// "Air India|Air India|Air India Express IX" -> "Air India" (marketing
  /// carrier name, aligned with the MAC code position).
  String _marketingSegment(String value, {required String fallback}) {
    final parts = value.split('|').map((p) => p.trim()).toList();
    if (parts.length > 1 && parts[1].isNotEmpty) return parts[1];
    final firstNonEmpty = parts.firstWhere((p) => p.isNotEmpty, orElse: () => '');
    return firstNonEmpty.isNotEmpty ? firstNonEmpty : fallback;
  }

  /// "Bengaluru International Airport |Bangalore" -> "Bangalore"
  String _lastSegment(String value) {
    final parts = value.split('|');
    final last = parts.last.trim();
    return last.isNotEmpty ? last : value.trim();
  }

  String _formatApiTime(String isoTime) {
    if (isoTime.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }

  /// "2026-08-01T10:30:00" -> "01 Aug 2026", for display on the ticket
  /// confirmation screen (departureTime only carries the time-of-day).
  String _formatApiDate(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(isoTime));
    } catch (_) {
      return '';
    }
  }

  /// "01h 25m " -> "1h 25m"
  String _cleanDuration(String duration) {
    final hours = int.tryParse(RegExp(r'(\d+)h').firstMatch(duration)?.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(RegExp(r'(\d+)m').firstMatch(duration)?.group(1) ?? '') ?? 0;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    return duration.trim();
  }

  String? _layoverLabel(String arrivalIso, String departureIso) {
    try {
      final arrival = DateTime.parse(arrivalIso);
      final departure = DateTime.parse(departureIso);
      final gap = departure.difference(arrival);
      if (gap.isNegative) return null;
      final h = gap.inHours;
      final m = gap.inMinutes % 60;
      if (h > 0 && m > 0) return '${h}h ${m}m';
      if (h > 0) return '${h}h';
      return '${m}m';
    } catch (_) {
      return null;
    }
  }

  String _formatAmount(double amount) {
    final rounded = amount.round();
    final str = rounded.toString();
    if (str.length <= 3) return '₹$str';
    final last3 = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    var formatted = '';
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) formatted += ',';
      formatted += remaining[i];
    }
    return '₹$formatted,$last3';
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

  // ---------------------------------------------------------------------------
  // Shared ticket-style pieces (unchanged look & feel from the original design)
  // ---------------------------------------------------------------------------
  Widget _timeBlock(BuildContext context, String time, String code, bool alignRight) {
    return SizedBox(
      width: context.w(62),
      child: Column(
        crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: TextStyle(
              color: const Color(0xff3D3F4A),
              fontSize: context.fs(19),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: context.h(3)),
          Text(
            code,
            style: TextStyle(
              color: const Color(0xffA0A6C2),
              fontSize: context.fs(11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _flightPath(BuildContext context) {
    const color = Color(0xff5F86FF);
    return Row(
      children: [
        _pathDot(context, color),
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
            child: SizedBox(height: context.h(1)),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(4)),
          child: Icon(Icons.flight, color: color, size: context.w(20)),
        ),
        Expanded(
          child: CustomPaint(
            painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
            child: SizedBox(height: context.h(1)),
          ),
        ),
        _pathDot(context, color),
      ],
    );
  }

  Widget _pathDot(BuildContext context, Color color) {
    return Container(
      width: context.w(7),
      height: context.w(7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.26), blurRadius: context.w(6), spreadRadius: context.w(1)),
        ],
      ),
    );
  }

  Widget _dashedDivider(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
      child: SizedBox(width: double.infinity, height: context.h(1)),
    );
  }

  Widget _metaChip(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: const Color(0xffA0A6C2), fontSize: context.fs(9), fontWeight: FontWeight.w600),
        ),
        SizedBox(height: context.h(3)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: const Color(0xffE6ECFF)),
          ),
          child: Text(
            value,
            style: TextStyle(color: const Color(0xff3D3F4A), fontSize: context.fs(10), fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
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
    var startX = 0.0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(math.min(startX + dashWidth, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DetailTicketPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _DetailTicketPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    const notchRadius = 13.0;
    const radius = 18.0;
    final notchY = size.height * 0.62;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(radius)));
    final leftNotch = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: notchRadius));
    final rightNotch = Path()
      ..addOval(Rect.fromCircle(center: Offset(size.width, notchY), radius: notchRadius));
    final cutLeft = Path.combine(PathOperation.difference, path, leftNotch);
    final ticket = Path.combine(PathOperation.difference, cutLeft, rightNotch);

    canvas.drawShadow(ticket, shadowColor, 12, true);
    canvas.drawPath(ticket, Paint()..color = color);
    canvas.drawPath(
      ticket,
      Paint()
        ..color = const Color(0xffE6ECFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DetailTicketPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }
}
