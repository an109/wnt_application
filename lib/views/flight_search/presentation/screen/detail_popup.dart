// import 'dart:async';
// import 'dart:math' as math;
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
// import 'package:wander_nova/injection_container.dart';
// import 'package:wander_nova/views/AKFlightInfo/domain/entity/AKFlightInfo_entity.dart';
// import 'package:wander_nova/views/AKFlightInfo/presentation/bloc/AKFlightInfo_bloc.dart';
// import 'package:wander_nova/views/AKFlightInfo/presentation/bloc/AKFlightInfo_event.dart';
// import 'package:wander_nova/views/AKFlightInfo/presentation/bloc/AKFlightInfo_state.dart';
// import 'package:wander_nova/views/AKGetSPricer/domain/entity/AKGetSPricer_entity.dart';
// import 'package:wander_nova/views/AKGetSPricer/presentation/bloc/AKGetSPricer_bloc.dart';
// import 'package:wander_nova/views/AKGetSPricer/presentation/bloc/AKGetSPricer_event.dart';
// import 'package:wander_nova/views/AKGetSPricer/presentation/bloc/AKGetSPricer_state.dart';
// import 'package:wander_nova/views/AKSmartPricer/domain/entity/AKSmartPricer_entity.dart';
// import 'package:wander_nova/views/AKSmartPricer/presentation/bloc/AKSmartPricer_bloc.dart';
// import 'package:wander_nova/views/AKSmartPricer/presentation/bloc/AKSmartPricer_event.dart';
// import 'package:wander_nova/views/AKSmartPricer/presentation/bloc/AKSmartPricer_state.dart';
// import 'package:wander_nova/views/AKAcceptFareChange/domain/entity/AKAcceptFareChange_entity.dart';
// import 'package:wander_nova/views/AKAcceptFareChange/domain/usecase/AKAcceptFareChange_usecase.dart';
// import 'package:wander_nova/views/AKFareRule/domain/entity/AKFareRule_entity.dart';
// import 'package:wander_nova/views/AKFareRule/domain/usecase/AKFareRule_usecase.dart';
// import 'package:wander_nova/views/AKFareRule/presentation/screen/ak_fare_rule_popup.dart';
// import 'package:wander_nova/core/error/data_state.dart';
// import 'package:wander_nova/views/flight_search/domain/entities/flight_entity.dart' show FareFamilyIndexEntity;
// import 'package:wander_nova/views/flight_search/domain/entities/fare_trip_type.dart';
// import 'package:wander_nova/views/AKSmartPricer/domain/usecase/AKSmartPricer_usecase.dart';
// import 'package:wander_nova/views/AKGetSPricer/domain/usecase/AKGetSPricer_usecase.dart';
// import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
// import 'package:wander_nova/views/flight_search/presentation/screen/seat_addons_screen.dart';
//
// class FlightDetailsPopup extends StatefulWidget {
//   // Needed to call FlightInfo: the search's tui and the chosen result's
//   // Index + fare amount (as returned by GetExpSearch).
//   final String tui;
//   final String resultIndex;
//   final double amount;
//
//   // Shown immediately while FlightInfo loads, before the real segment/fare
//   // data is available.
//   final String airlineName;
//   final String airlineCode;
//   final String flightNumber;
//   final String fromCode;
//   final String toCode;
//   final String departureTime;
//   final String arrivalTime;
//   final String duration;
//   final String price;
//   final String? traceId;
//
//   /// Number of travellers — forwarded to booking → SSR for seat selection.
//   final int travellerCount;
//
//   /// Sibling fare-class variants of this same physical flight (Saver/Flexi/
//   /// SME/...), preserved from GetExpSearch by flight_search_screen.dart's
//   /// `_cheapestPerFlight` instead of being discarded. Null/empty when the
//   /// flight only has one fare — the "Choose Your Fare" section then just
//   /// shows the single (tapped) fare.
//   final List<FareFamilyIndexEntity>? fareFamilyOptions;
//
//   /// Wire fareType ('ON'/'RT'/'RS'/'DM'/'IM'). Defaults to 'ON' so every
//   /// existing one-way call site keeps sending exactly what it does today.
//   final String tripType;
//
//   /// Additional legs beyond the one described by the fields above (which is
//   /// always leg 1 / orderId 1) — the return leg for RT/RS, or legs 2..N for
//   /// Multi City. Empty for 'ON', where there is only ever one leg. This
//   /// popup is only ever opened once per search — for 'ON' with the tapped
//   /// flight, or for RT/RS/IM/DM once every column has a pick — so it always
//   /// runs the real booking chain; there's no separate "preview" mode.
//   final List<FlightLegSelection> additionalLegs;
//
//   const FlightDetailsPopup({
//     super.key,
//     required this.tui,
//     required this.resultIndex,
//     required this.amount,
//     required this.airlineName,
//     required this.airlineCode,
//     required this.flightNumber,
//     required this.fromCode,
//     required this.toCode,
//     required this.departureTime,
//     required this.arrivalTime,
//     required this.duration,
//     required this.price,
//     this.traceId,
//     this.travellerCount = 1,
//     this.fareFamilyOptions,
//     this.tripType = 'ON',
//     this.additionalLegs = const [],
//   });
//
//   static void show(
//       BuildContext context, {
//         required String tui,
//         required String resultIndex,
//         required double amount,
//         required String airlineName,
//         required String airlineCode,
//         required String flightNumber,
//         required String fromCode,
//         required String toCode,
//         required String departureTime,
//         required String arrivalTime,
//         required String duration,
//         required String price,
//         String? traceId,
//         int travellerCount = 1,
//         List<FareFamilyIndexEntity>? fareFamilyOptions,
//         String tripType = 'ON',
//         List<FlightLegSelection> additionalLegs = const [],
//       }) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       backgroundColor: Colors.transparent,
//       barrierColor: Colors.black.withValues(alpha: 0.55),
//       builder: (_) => FlightDetailsPopup(
//         tui: tui,
//         resultIndex: resultIndex,
//         amount: amount,
//         airlineName: airlineName,
//         airlineCode: airlineCode,
//         flightNumber: flightNumber,
//         fromCode: fromCode,
//         toCode: toCode,
//         departureTime: departureTime,
//         arrivalTime: arrivalTime,
//         duration: duration,
//         price: price,
//         traceId: traceId,
//         travellerCount: travellerCount,
//         fareFamilyOptions: fareFamilyOptions,
//         tripType: tripType,
//         additionalLegs: additionalLegs,
//       ),
//     );
//   }
//
//   @override
//   State<FlightDetailsPopup> createState() => _FlightDetailsPopupState();
// }
//
// /// Live per-fare-option data (GetSPricer's baggage/price, FareRule's
// /// cancellation/change text) fetched in parallel for every "Choose Your
// /// Fare" card — Paytm/AkbarFareConfirmModal-style, all cards show real data
// /// at once instead of only the one the user tapped.
// class _FareCardPreview {
//   final AkGetSPricerEntity? pricer;
//   final List<String> ruleTexts;
//   final bool loading;
//
//   const _FareCardPreview({this.pricer, this.ruleTexts = const [], this.loading = true});
// }
//
// class _FlightDetailsPopupState extends State<FlightDetailsPopup> {
//   late final AkFlightInfoBloc _bloc;
//   late final AkSmartPricerBloc _smartPricerBloc;
//   late final AkGetSPricerBloc _pricerBloc;
//
//   // One-shot usecases (not blocs) used to fetch every fare card's preview
//   // data in parallel — a bloc only ever holds one in-flight request/response,
//   // which can't drive N independently-loading cards at once.
//   late final AkSmartPricerUseCase _smartPricerUseCase;
//   late final AkGetSPricerUseCase _getSPricerUseCase;
//   late final AkFareRuleUseCase _fareRuleUseCase;
//
//   // Guards against re-firing SmartPricer/GetSPricer on every rebuild once
//   // their preceding step has loaded — each should only be requested once
//   // per sheet open.
//   bool _smartPricerRequested = false;
//   bool _pricerRequested = false;
//
//   /// Every fare card's own live baggage/price/cancellation data, keyed by
//   /// its search Index — populated by [_loadAllFareCardPreviews] the moment
//   /// the sheet opens, in parallel, independent of which fare is selected.
//   final Map<String, _FareCardPreview> _cardPreviews = {};
//
//   // Captured off SmartPricer/GetSPricer's own responses — threaded into
//   // FlightRouteSegment for booking_screen.dart's Akbar CreateItinerary/
//   // StartPay chain. sessionId is the one identifier that flows through
//   // the entire rest of the booking (AcceptFareChange, GetTravelCheckList,
//   // CreateItinerary, StartPay, RetrieveBooking, and the CCAvenue payment
//   // reference_id).
//   String? _sessionId;
//   String? _pricingTui;
//   AkGetSPricerEntity? _pricerData;
//   bool _fareChangeAccepted = false;
//
//   // Fare-family selector. Sourced from widget.fareFamilyOptions (GetExpSearch's
//   // sibling Index/amount/refundable, preserved by flight_search_screen.dart)
//   // rather than re-fetched — that data is already known before this screen
//   // even opens. `_selectedIndex`/`_selectedAmount` track which one is
//   // currently being previewed; they start at the originally tapped fare.
//   late String _selectedIndex = widget.resultIndex;
//   late double _selectedAmount = widget.amount;
//   bool _switchingFare = false;
//   // True only while the final, non-preview commit (SmartPricer+GetSPricer
//   // with preview:false) is in flight, right after Book Now is tapped.
//   bool _committing = false;
//
//   List<FareFamilyIndexEntity> get _fareOptions {
//     final options = widget.fareFamilyOptions;
//     if (options != null && options.isNotEmpty) return options;
//     return [FareFamilyIndexEntity(index: widget.resultIndex, amount: widget.amount, refundable: true)];
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _bloc = sl<AkFlightInfoBloc>();
//     _smartPricerBloc = sl<AkSmartPricerBloc>();
//     _pricerBloc = sl<AkGetSPricerBloc>();
//     _smartPricerUseCase = sl<AkSmartPricerUseCase>();
//     _getSPricerUseCase = sl<AkGetSPricerUseCase>();
//     _fareRuleUseCase = sl<AkFareRuleUseCase>();
//     _load();
//     _loadAllFareCardPreviews();
//   }
//
//   /// Fires SmartPricer(preview)->GetSPricer(preview) + FareRule for every
//   /// fare option at once — Future.wait per option, all options in parallel
//   /// (mirrors the web app's `Promise.all(fareOptions.map(...))` in
//   /// AkbarFareConfirmModal.jsx) — so every card shows real baggage/price/
//   /// cancellation data as soon as it resolves, instead of only the fare the
//   /// user happens to have tapped. Independent of the FlightInfo/booking-
//   /// commit chain below (`_load`/`_bloc`/`_sessionId`/`_pricingTui`), which
//   /// still only ever tracks the currently selected fare.
//   void _loadAllFareCardPreviews() {
//     for (final option in _fareOptions) {
//       _cardPreviews[option.index] = const _FareCardPreview();
//       unawaited(_loadFareCardPreview(option));
//     }
//   }
//
//   Future<void> _loadFareCardPreview(FareFamilyIndexEntity option) async {
//     final smartPricerTrips = [
//       AkSmartPricerTripRequestEntity(index: option.index, amount: option.amount, orderId: 1),
//       for (final leg in widget.additionalLegs)
//         AkSmartPricerTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
//     ];
//     final fareRuleTrips = [
//       AkFareRuleTripRequestEntity(index: option.index, amount: option.amount, orderId: 1),
//       for (final leg in widget.additionalLegs)
//         AkFareRuleTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
//     ];
//
//     // Pricing/baggage and fare-rule text are independent Akbar calls — run
//     // them together so a slow one never holds up the other.
//     final results = await Future.wait([
//       _fetchPricerPreview(option, smartPricerTrips),
//       _fetchRuleTexts(fareRuleTrips),
//     ]);
//
//     if (!mounted) return;
//     setState(() {
//       _cardPreviews[option.index] = _FareCardPreview(
//         pricer: results[0] as AkGetSPricerEntity?,
//         ruleTexts: results[1] as List<String>,
//         loading: false,
//       );
//     });
//   }
//
//   /// SmartPricer(preview:true) -> GetSPricer(preview:true) for one fare
//   /// option, run outside any bloc so N of these can be in flight at once.
//   /// `preview: true` throughout — the real backend never writes these to
//   /// the session, so browsing every card's live price is free.
//   Future<AkGetSPricerEntity?> _fetchPricerPreview(
//       FareFamilyIndexEntity option, List<AkSmartPricerTripRequestEntity> trips) async {
//     try {
//       final smart = await _smartPricerUseCase(AkSmartPricerRequestEntity(
//         searchTui: widget.tui,
//         tripType: widget.tripType,
//         trips: trips,
//         preview: true,
//       ));
//       if (smart is! DataSuccess<AkSmartPricerEntity> || smart.data == null) return null;
//       final priced = await _getSPricerUseCase(AkGetSPricerRequestEntity(tui: smart.data!.tui, preview: true));
//       return priced is DataSuccess<AkGetSPricerEntity> ? priced.data : null;
//     } catch (_) {
//       // Best-effort — the card just falls back to its search-time price and
//       // "As per airline policy" baggage text.
//       return null;
//     }
//   }
//
//   Future<List<String>> _fetchRuleTexts(List<AkFareRuleTripRequestEntity> trips) async {
//     try {
//       final result = await _fareRuleUseCase(AkFareRuleRequestEntity(tui: widget.tui, trips: trips));
//       return result is DataSuccess<AkFareRuleEntity> ? (result.data?.ruleTexts ?? const []) : const [];
//     } catch (_) {
//       return const [];
//     }
//   }
//
//   void _load() {
//     _bloc.add(LoadAkFlightInfoEvent(
//       AkFlightInfoRequestEntity(
//         tui: widget.tui,
//         tripType: widget.tripType,
//         trips: [
//           AkFlightInfoTripRequestEntity(
//             index: _selectedIndex,
//             amount: _selectedAmount,
//             orderId: 1,
//           ),
//           for (final leg in widget.additionalLegs)
//             AkFlightInfoTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
//         ],
//       ),
//     ));
//   }
//
//   /// SmartPricer initiates re-pricing and hands back a fresh (pricing) tui —
//   /// called automatically once FlightInfo resolves. Must be called with the
//   /// original ExpressSearch/GetExpSearch search tui (widget.tui) — NOT
//   /// FlightInfo's own returned tui; passing it here gets Akbar's "No Record
//   /// found". `preview` defaults true here: this auto-chain fires the moment
//   /// the sheet opens (or the user switches fares) purely to show live
//   /// price/baggage — the real backend docs call this exact case "a flight
//   /// the user is only peeking at", and it must not overwrite
//   /// session.pricing_tui. Only the Book Now commit step passes preview:false.
//   void _loadSmartPricer(String searchTui, {bool preview = true}) {
//     _smartPricerRequested = true;
//     _smartPricerBloc.add(LoadAkSmartPricerEvent(
//       AkSmartPricerRequestEntity(
//         searchTui: searchTui,
//         tripType: widget.tripType,
//         trips: [
//           AkSmartPricerTripRequestEntity(
//             index: _selectedIndex,
//             amount: _selectedAmount,
//             orderId: 1,
//           ),
//           for (final leg in widget.additionalLegs)
//             AkSmartPricerTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
//         ],
//         preview: preview,
//       ),
//     ));
//   }
//
//   /// GetSPricer re-confirms live fare/flight details using the tui
//   /// SmartPricer just returned — called automatically once SmartPricer
//   /// resolves. (SmartPricer's data may be served from cache; GetSPricer's
//   /// tui must be used here, not FlightInfo's, to get live fare data.) Same
//   /// preview semantics as SmartPricer — see [_loadSmartPricer].
//   void _loadPricer(String smartPricerTui, {bool preview = true}) {
//     _pricerRequested = true;
//     _pricerBloc.add(LoadAkGetSPricerEvent(
//       AkGetSPricerRequestEntity(tui: smartPricerTui, preview: preview),
//     ));
//   }
//
//   /// Switches which fare family (real GetExpSearch Index, from
//   /// widget.fareFamilyOptions) is currently being browsed. Re-runs the whole
//   /// FlightInfo -> SmartPricer(preview) -> GetSPricer(preview) -> FareRule
//   /// chain for that index — a genuinely different itinerary needs its own
//   /// FlightInfo, not just a re-price — and stays in preview mode: nothing
//   /// here commits session.pricing_tui, so switching back and forth while
//   /// browsing is free. Book Now (see [_confirmAndBookNow]) is what commits.
//   void _selectFare(FareFamilyIndexEntity option) {
//     if (option.index == _selectedIndex || _switchingFare) return;
//     setState(() {
//       _selectedIndex = option.index;
//       _selectedAmount = option.amount;
//       _switchingFare = true;
//       _smartPricerRequested = false;
//       _pricerRequested = false;
//       _sessionId = null;
//       _pricingTui = null;
//       _pricerData = null;
//     });
//     _load();
//   }
//
//   @override
//   void dispose() {
//     _bloc.close();
//     _smartPricerBloc.close();
//     _pricerBloc.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider<AkFlightInfoBloc>.value(value: _bloc),
//         BlocProvider<AkSmartPricerBloc>.value(value: _smartPricerBloc),
//         BlocProvider<AkGetSPricerBloc>.value(value: _pricerBloc),
//       ],
//       child: MultiBlocListener(
//         listeners: [
//           BlocListener<AkFlightInfoBloc, AkFlightInfoState>(
//             listener: (context, state) {
//               if (state is AkFlightInfoLoaded && !_smartPricerRequested) {
//                 _loadSmartPricer(widget.tui);
//               }
//             },
//           ),
//           BlocListener<AkSmartPricerBloc, AkSmartPricerState>(
//             listener: (context, state) {
//               if (state is AkSmartPricerLoaded) {
//                 _sessionId = state.data.sessionId;
//                 if (!_pricerRequested) {
//                   _loadPricer(state.data.tui);
//                 }
//               } else if (state is AkSmartPricerFailed && _switchingFare) {
//                 _switchingFare = false;
//               }
//             },
//           ),
//           BlocListener<AkGetSPricerBloc, AkGetSPricerState>(
//             listener: (context, state) {
//               if (state is AkGetSPricerLoaded) {
//                 _pricingTui = state.data.tui;
//                 _pricerData = state.data;
//                 _switchingFare = false;
//               } else if (state is AkGetSPricerFailed && _switchingFare) {
//                 _switchingFare = false;
//               }
//             },
//           ),
//         ],
//         child: Padding(
//           padding: EdgeInsets.only(
//             left: context.w(10),
//             right: context.w(10),
//             bottom: MediaQuery.of(context).viewInsets.bottom + context.h(8),
//           ),
//           child: Container(
//             constraints: BoxConstraints(maxHeight: context.screenHeight * 0.88),
//             decoration: BoxDecoration(
//               color: const Color(0xffF4F7FF),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(22))),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.18),
//                   blurRadius: context.w(22),
//                   offset: Offset(0, -context.h(6)),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(22))),
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: EdgeInsets.fromLTRB(
//                     context.w(14),
//                     context.h(8),
//                     context.w(14),
//                     context.h(14),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: context.w(36),
//                         height: context.h(3.5),
//                         decoration: BoxDecoration(
//                           color: const Color(0xffCBD5E1),
//                           borderRadius: BorderRadius.circular(context.r(4)),
//                         ),
//                       ),
//                       SizedBox(height: context.h(10)),
//                       _header(context),
//                       if (widget.additionalLegs.isNotEmpty) ...[
//                         SizedBox(height: context.h(8)),
//                         _additionalLegsSummary(context),
//                       ],
//                       SizedBox(height: context.h(12)),
//                       // Rendered here, outside the FlightInfo BlocBuilder
//                       // below, so the fare picker (and its own inline
//                       // "Re-pricing…" indicator) stays visible and tappable
//                       // while switching fares reloads the ticket/itinerary
//                       // section beneath it, instead of the whole sheet
//                       // blanking out to a single spinner.
//                       if (_fareOptions.length > 1) ...[
//                         _verticalFareCards(context, _fareOptions),
//                         SizedBox(height: context.h(10)),
//                       ],
//                       BlocBuilder<AkFlightInfoBloc, AkFlightInfoState>(
//                         builder: (context, flightInfoState) {
//                           if (flightInfoState is AkFlightInfoFailed) {
//                             return _errorState(
//                               context,
//                               flightInfoState.error.message ?? 'Failed to load flight details',
//                             );
//                           }
//                           if (flightInfoState is AkFlightInfoLoaded) {
//                             // GetSPricer re-confirms price/fare details using
//                             // FlightInfo's tui. While it's still in flight
//                             // (or if it fails), keep showing FlightInfo's own
//                             // data rather than blocking on a second spinner —
//                             // the numbers below just refine once it resolves.
//                             return BlocBuilder<AkGetSPricerBloc, AkGetSPricerState>(
//                               builder: (context, pricerState) {
//                                 if (pricerState is AkGetSPricerLoaded) {
//                                   final merged = _mergeWithPricer(
//                                     flightInfoState.data,
//                                     pricerState.data,
//                                   );
//                                   return _loadedContent(
//                                     context,
//                                     merged,
//                                     includedBaggage: pricerState.data.includedBaggage,
//                                     fareChanged: pricerState.data.fareChanged,
//                                   );
//                                 }
//                                 return _loadedContent(context, flightInfoState.data);
//                               },
//                             );
//                           }
//                           return _loadingState(context);
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------------
//   // Header (shown immediately, before FlightInfo resolves)
//   // ---------------------------------------------------------------------------
//   Widget _header(BuildContext context) {
//     return Row(
//       children: [
//         _airlineBadge(context, widget.airlineCode, widget.airlineName, size: context.w(32)),
//         SizedBox(width: context.w(8)),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.airlineName,
//                 style: TextStyle(
//                   color: const Color(0xff07163B),
//                   fontSize: context.fs(13),
//                   fontWeight: FontWeight.w800,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               SizedBox(height: context.h(1)),
//               Text(
//                 'Flight ${widget.flightNumber}',
//                 style: TextStyle(
//                   color: const Color(0xff8D95B3),
//                   fontSize: context.fs(10),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         InkWell(
//           borderRadius: BorderRadius.circular(context.r(16)),
//           onTap: () => Navigator.pop(context),
//           child: Container(
//             width: context.w(28),
//             height: context.w(28),
//             decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
//             child: Icon(Icons.close, color: const Color(0xff4B5563), size: context.w(15)),
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// Compact summary of every leg beyond the first (return leg for RT/RS,
//   /// legs 2..N for Multi City) — the price/fare breakdown below already
//   /// covers all of them combined (FlightInfo/SmartPricer/GetSPricer were
//   /// sent every leg's index/orderId), this just makes clear to the user
//   /// which flights that combined total actually includes.
//   Widget _additionalLegsSummary(BuildContext context) {
//     return Column(
//       children: widget.additionalLegs.map((leg) {
//         final f = leg.flight;
//         return Container(
//           margin: EdgeInsets.only(bottom: context.h(6)),
//           padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(8)),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(context.r(10)),
//             border: Border.all(color: const Color(0xffE9EDF6)),
//           ),
//           child: Row(
//             children: [
//               _airlineBadge(context, f.airlineCode ?? '--', f.airlineName ?? 'Airline', size: context.w(26)),
//               SizedBox(width: context.w(8)),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '${f.originName ?? f.origin ?? ''} → ${f.destinationName ?? f.destination ?? ''}',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: const Color(0xff07163B),
//                         fontSize: context.fs(12),
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     Text(
//                       '${f.airlineName ?? 'Airline'} · ${f.flightNumber ?? ''}',
//                       style: TextStyle(
//                         color: const Color(0xff8D95B3),
//                         fontSize: context.fs(10),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   // ---------------------------------------------------------------------------
//   // Loading / error states
//   // ---------------------------------------------------------------------------
//   Widget _loadingState(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: context.h(40)),
//       child: Column(
//         children: [
//           SizedBox(
//             width: context.w(28),
//             height: context.w(28),
//             child: const CircularProgressIndicator(strokeWidth: 2.4),
//           ),
//           SizedBox(height: context.h(12)),
//           Text(
//             'Fetching latest fare & flight details...',
//             style: TextStyle(
//               color: const Color(0xff6B7280),
//               fontSize: context.fs(12),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _errorState(BuildContext context, String message) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: context.h(28)),
//       child: Column(
//         children: [
//           Icon(Icons.error_outline, color: Colors.red.shade400, size: context.w(30)),
//           SizedBox(height: context.h(10)),
//           Text(
//             message,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: const Color(0xff4B5563),
//               fontSize: context.fs(12),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: context.h(12)),
//           TextButton(
//             onPressed: _load,
//             child: Text(
//               'Retry',
//               style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w800),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------------
//   // Loaded content — everything below is built from the real FlightInfo
//   // response, not placeholders.
//   // ---------------------------------------------------------------------------
//   Widget _loadedContent(
//       BuildContext context,
//       AkFlightInfoEntity data, {
//         Map<String, Map<String, AkGetSPricerBaggageEntity>> includedBaggage = const {},
//         bool fareChanged = false,
//       }) {
//     // Exactly one journey is ever fetched now — FlightInfo/SmartPricer/
//     // GetSPricer each take exactly one `trips: [{index, amount, order_id}]`
//     // and return exactly one journey for it (confirmed against the real
//     // backend). No need to search a list by order_id anymore.
//     final journey = data.trips.isNotEmpty && data.trips.first.journey.isNotEmpty
//         ? data.trips.first.journey.first
//         : null;
//
//     if (journey == null || journey.segments.isEmpty) {
//       return _errorState(context, 'No flight details available for this fare.');
//     }
//
//     final segments = journey.segments;
//     final stops = segments.length - 1;
//     final firstFlight = segments.first.flight;
//     final lastFlight = segments.last.flight;
//     final isFullyRefundable =
//     segments.every((s) => s.flight.refundable.toUpperCase() == 'Y');
//     final minSeats = segments
//         .map((s) => s.flight.seats)
//         .fold<int>(1 << 30, (m, s) => s < m ? s : m);
//
//     return Column(
//       children: [
//         if (fareChanged) ...[
//           _fareChangedBanner(context),
//           SizedBox(height: context.h(10)),
//         ],
//         _itinerary(context, segments, includedBaggage),
//         SizedBox(height: context.h(10)),
//         _amenities(context, isFullyRefundable, minSeats),
//         SizedBox(height: context.h(8)),
//         _features(context),
//         SizedBox(height: context.h(10)),
//         _bottomBar(context, data, journey, firstFlight, lastFlight, isFullyRefundable, fareChanged),
//       ],
//     );
//   }
//
//   Widget _fareChangedBanner(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(8)),
//       decoration: BoxDecoration(
//         color: const Color(0xffFFF7E6),
//         borderRadius: BorderRadius.circular(context.r(10)),
//         border: Border.all(color: const Color(0xffFACC15)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline, color: const Color(0xffB45309), size: context.w(14)),
//           SizedBox(width: context.w(6)),
//           Expanded(
//             child: Text(
//               'The fare for this flight has changed — prices below reflect the latest fare.',
//               style: TextStyle(
//                 color: const Color(0xffB45309),
//                 fontSize: context.fs(10),
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Merges GetSPricer's re-confirmed data into an [AkFlightInfoEntity] so
//   /// it flows through the same rendering as FlightInfo's own data — no
//   /// separate render path, just fresher numbers/segments once available.
//   ///
//   /// FlightInfo's response never carries a real session_id — only
//   /// SmartPricer's does — so this prefers the session_id captured off
//   /// SmartPricer's own response over FlightInfo's (usually empty) one.
//   AkFlightInfoEntity _mergeWithPricer(AkFlightInfoEntity flightInfo, AkGetSPricerEntity pricer) {
//     AkFlightInfoFlightEntity mapFlight(AkGetSPricerFlightEntity f) => AkFlightInfoFlightEntity(
//       fuid: f.fuid,
//       vac: f.vac,
//       mac: f.mac,
//       oac: f.oac,
//       fbc: f.fbc,
//       airline: f.airline,
//       flightNo: f.flightNo,
//       departureTime: f.departureTime,
//       arrivalTime: f.arrivalTime,
//       fareClass: f.fareClass,
//       departureCode: f.departureCode,
//       arrivalCode: f.arrivalCode,
//       departureTerminal: f.departureTerminal,
//       arrivalTerminal: f.arrivalTerminal,
//       depAirportName: f.depAirportName,
//       arrAirportName: f.arrAirportName,
//       equipmentType: f.equipmentType,
//       aircraft: f.aircraft,
//       rbd: f.rbd,
//       cabin: f.cabin,
//       refundable: f.refundable,
//       seats: f.seats,
//       duration: f.duration,
//     );
//
//     AkFlightInfoFareEntity mapFare(AkGetSPricerFareEntity f) => AkFlightInfoFareEntity(
//       grossFare: f.grossFare,
//       netFare: f.netFare,
//       totalBaseFare: f.totalBaseFare,
//       totalTax: f.totalTax,
//       totalServiceTax: f.totalServiceTax,
//       totalTransactionFee: f.totalTransactionFee,
//       totalCommission: f.totalCommission,
//     );
//
//     AkFlightInfoTripEntity mapTrip(AkGetSPricerTripEntity t) => AkFlightInfoTripEntity(
//       journey: t.journey
//           .map((j) => AkFlightInfoJourneyEntity(
//         provider: j.provider,
//         stops: j.stops,
//         orderId: j.orderId,
//         grossFare: j.grossFare,
//         netFare: j.netFare,
//         duration: j.duration,
//         promo: j.promo,
//         fareType: j.fareType,
//         segments: j.segments
//             .map((s) => AkFlightInfoSegmentEntity(
//           flight: mapFlight(s.flight),
//           fare: mapFare(s.fare),
//         ))
//             .toList(),
//       ))
//           .toList(),
//     );
//
//     return AkFlightInfoEntity(
//       success: pricer.success,
//       sessionId: _sessionId ?? flightInfo.sessionId,
//       tui: pricer.tui,
//       from: pricer.from,
//       to: pricer.to,
//       fromName: pricer.fromName,
//       toName: pricer.toName,
//       onwardDate: pricer.onwardDate,
//       returnDate: pricer.returnDate,
//       adultCount: pricer.adultCount,
//       childCount: pricer.childCount,
//       infantCount: pricer.infantCount,
//       netAmount: pricer.netAmount,
//       grossAmount: pricer.grossAmount,
//       fareType: pricer.fareType,
//       hold: flightInfo.hold,
//       trips: pricer.trips.map(mapTrip).toList(),
//     );
//   }
//
//   AkGetSPricerBaggageEntity? _baggageFor(
//       Map<String, Map<String, AkGetSPricerBaggageEntity>> includedBaggage,
//       int fuid,
//       ) {
//     final byPtc = includedBaggage[fuid.toString()];
//     if (byPtc == null || byPtc.isEmpty) return null;
//     return byPtc['ADT'] ?? byPtc.values.first;
//   }
//
//   // ---------------------------------------------------------------------------
//   // Itinerary — one card per real flight segment, with a layover connector
//   // between legs for connecting flights.
//   // ---------------------------------------------------------------------------
//   Widget _itinerary(
//       BuildContext context,
//       List<AkFlightInfoSegmentEntity> segments,
//       Map<String, Map<String, AkGetSPricerBaggageEntity>> includedBaggage,
//       ) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.w(12)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.r(14)),
//         border: Border.all(color: const Color(0xffE6ECFF)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Flight Itinerary',
//             style: TextStyle(
//               color: const Color(0xff07163B),
//               fontSize: context.fs(12),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           SizedBox(height: context.h(10)),
//           for (var i = 0; i < segments.length; i++) ...[
//             _segmentRow(
//               context,
//               segments[i].flight,
//               _baggageFor(includedBaggage, segments[i].flight.fuid),
//             ),
//             if (i < segments.length - 1)
//               _layoverRow(context, segments[i].flight, segments[i + 1].flight),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _segmentRow(
//       BuildContext context,
//       AkFlightInfoFlightEntity flight,
//       AkGetSPricerBaggageEntity? baggage,
//       ) {
//     final code = _airlineCodeOf(flight);
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _airlineBadge(context, code, flight.airline, size: context.w(26)),
//         SizedBox(width: context.w(8)),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '${_marketingSegment(flight.airline, fallback: code)} · $code${flight.flightNo}',
//                 style: TextStyle(
//                   color: const Color(0xff07163B),
//                   fontSize: context.fs(11),
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               SizedBox(height: context.h(4)),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _segmentEndpoint(
//                       context,
//                       time: _formatApiTime(flight.departureTime),
//                       code: flight.departureCode,
//                       name: _lastSegment(flight.depAirportName),
//                       terminal: flight.departureTerminal,
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: context.w(6)),
//                     child: Icon(Icons.arrow_forward, size: context.w(13), color: const Color(0xffA0A6C2)),
//                   ),
//                   Expanded(
//                     child: _segmentEndpoint(
//                       context,
//                       time: _formatApiTime(flight.arrivalTime),
//                       code: flight.arrivalCode,
//                       name: _lastSegment(flight.arrAirportName),
//                       terminal: flight.arrivalTerminal,
//                       alignRight: true,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: context.h(6)),
//               Wrap(
//                 spacing: context.w(6),
//                 runSpacing: context.h(4),
//                 children: [
//                   _tag(context, _cleanDuration(flight.duration)),
//                   if (flight.cabin.isNotEmpty) _tag(context, flight.cabin == 'E' ? 'Economy' : flight.cabin),
//                   if (flight.aircraft.isNotEmpty) _tag(context, flight.aircraft),
//                   _tag(context, flight.refundable.toUpperCase() == 'Y' ? 'Refundable' : 'Non-refundable'),
//                   if (baggage != null && baggage.checkin.isNotEmpty)
//                     _tag(context, '${baggage.checkin} check-in'),
//                   if (baggage != null && baggage.cabin.isNotEmpty)
//                     _tag(context, '${baggage.cabin} cabin'),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _segmentEndpoint(
//       BuildContext context, {
//         required String time,
//         required String code,
//         required String name,
//         required String terminal,
//         bool alignRight = false,
//       }) {
//     return Column(
//       crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Text(
//           time,
//           style: TextStyle(
//             color: const Color(0xff3D3F4A),
//             fontSize: context.fs(14),
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//         Text(
//           terminal.isNotEmpty ? '$code · T$terminal' : code,
//           style: TextStyle(
//             color: const Color(0xffA0A6C2),
//             fontSize: context.fs(10),
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         Text(
//           name,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(
//             color: const Color(0xff9AA2BF),
//             fontSize: context.fs(9),
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _tag(BuildContext context, String label) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: context.w(7), vertical: context.h(2)),
//       decoration: BoxDecoration(
//         color: const Color(0xffF3F6FF),
//         borderRadius: BorderRadius.circular(context.r(8)),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: const Color(0xff5F86FF),
//           fontSize: context.fs(9),
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }
//
//   Widget _layoverRow(
//       BuildContext context,
//       AkFlightInfoFlightEntity arriving,
//       AkFlightInfoFlightEntity departing,
//       ) {
//     final layover = _layoverLabel(arriving.arrivalTime, departing.departureTime);
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: context.h(10)),
//       child: Row(
//         children: [
//           SizedBox(width: context.w(26), child: Icon(Icons.schedule, size: context.w(13), color: const Color(0xffF59E0B))),
//           SizedBox(width: context.w(8)),
//           Expanded(
//             child: Text(
//               layover != null
//                   ? 'Change planes at ${arriving.arrivalCode} · $layover layover'
//                   : 'Change of flight at ${arriving.arrivalCode}',
//               style: TextStyle(
//                 color: const Color(0xffB45309),
//                 fontSize: context.fs(10),
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------------
//   // Fare family cards — restyled to match the web app's AkbarFareConfirmModal
//   // (D:\WNT_Frontend\wandernova-front\src\components\Frontcopy\
//   // AkbarFareConfirmModal.jsx): navy-bordered selected card with a "Lowest
//   // price"/tick badge overlapping the top edge, a blue fare title, a dashed
//   // divider, and icon-labeled Baggage / Flexibility / Seat & meal sections
//   // instead of a plain label:value list. Still a horizontal scrollable row
//   // (the web version is a CSS grid) since this is a bottom-sheet on mobile.
//   // ---------------------------------------------------------------------------
//   Widget _verticalFareCards(BuildContext context, List<FareFamilyIndexEntity> options) {
//     final sorted = [...options]..sort((a, b) => a.amount.compareTo(b.amount));
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               'CHOOSE YOUR FARE',
//               style: TextStyle(
//                 fontSize: context.fs(11),
//                 fontWeight: FontWeight.w800,
//                 color: const Color(0xff64748B),
//                 letterSpacing: 0.6,
//               ),
//             ),
//             // if (_switchingFare) ...[
//             //   SizedBox(width: context.w(8)),
//             //   SizedBox(
//             //     width: context.w(13),
//             //     height: context.w(13),
//             //     child: const CircularProgressIndicator(strokeWidth: 2),
//             //   ),
//             //   SizedBox(width: context.w(6)),
//             //   Text(
//             //     'Loading fare…',
//             //     style: TextStyle(fontSize: context.fs(10.5), color: const Color(0xff6B7280), fontWeight: FontWeight.w600),
//             //   ),
//             // ],
//           ],
//         ),
//         SizedBox(height: context.h(12)),
//         // Horizontal scrollable row of fare cards. Extra headroom above/below
//         // (vs. a tight-fit height) so the overlapping badges (top: -9) never
//         // get clipped by the list's own bounds.
//         SizedBox(
//           height: context.h(300),
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             padding: EdgeInsets.only(top: context.h(9)),
//             itemCount: sorted.length,
//             separatorBuilder: (_, __) => SizedBox(width: context.w(10)),
//             itemBuilder: (_, i) => SizedBox(
//               width: context.w(230),
//               child: _verticalFareCard(context, sorted[i], i),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _verticalFareCard(BuildContext context, FareFamilyIndexEntity option, int rank) {
//     final selected = option.index == _selectedIndex;
//     // `sorted` (the caller) is ascending by amount, so rank 0 is always the
//     // cheapest — matches the web modal's `option.price === cheapest` check.
//     final isCheapest = rank == 0;
//
//     // Every card reads from its own parallel-fetched preview — populated by
//     // [_loadAllFareCardPreviews] for ALL options at once, not gated behind
//     // selection/tapping. `selected` below only affects styling (border/
//     // badge) and what tapping the card does, never which data is shown.
//     final preview = _cardPreviews[option.index];
//     final pricer = preview?.pricer;
//     final stillLoading = preview == null || preview.loading;
//
//     final label = (pricer != null && pricer.fareType.isNotEmpty)
//         ? pricer.fareType
//         : (isCheapest ? 'Cheapest Fare' : 'Fare Option ${rank + 1}');
//     final hasLiveDiscount = pricer != null && pricer.grossAmount > pricer.netAmount;
//     final displayAmount = pricer?.netAmount ?? option.amount;
//
//     String checkinBaggageText = 'As per airline policy';
//     String cabinBaggageText = 'As per airline policy';
//     int? seatsLeft;
//     if (pricer != null) {
//       final firstFuid = pricer.trips.isNotEmpty && pricer.trips.first.journey.isNotEmpty
//           ? (pricer.trips.first.journey.first.segments.isNotEmpty
//           ? pricer.trips.first.journey.first.segments.first.flight.fuid
//           : null)
//           : null;
//       final baggage = firstFuid != null ? _baggageFor(pricer.includedBaggage, firstFuid) : null;
//       if (baggage != null && baggage.checkin.isNotEmpty) checkinBaggageText = baggage.checkin;
//       if (baggage != null && baggage.cabin.isNotEmpty) cabinBaggageText = baggage.cabin;
//
//       for (final trip in pricer.trips) {
//         for (final journey in trip.journey) {
//           for (final seg in journey.segments) {
//             seatsLeft = seatsLeft == null ? seg.flight.seats : math.min(seatsLeft, seg.flight.seats);
//           }
//         }
//       }
//     }
//
//     final ruleTexts = preview?.ruleTexts ?? const <String>[];
//     final cancelFee = _extractFeeText(ruleTexts, const ['cancellation', 'cancel']);
//     final changeFee = _extractFeeText(ruleTexts, const ['change', 'reissue']);
//
//     return GestureDetector(
//       onTap: !selected && !_switchingFare ? () => _selectFare(option) : null,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.fromLTRB(context.w(14), context.h(18), context.w(14), context.h(14)),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(context.r(12)),
//               border: Border.all(
//                 color: selected ? const Color(0xff0F2444) : const Color(0xffE5E7EB),
//                 width: selected ? 1.4 : 1,
//               ),
//               boxShadow: selected
//                   ? [BoxShadow(color: const Color(0xff0F2444).withValues(alpha: 0.18), blurRadius: 0, spreadRadius: 2)]
//                   : null,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w800, color: const Color(0xff2563EB)),
//                 ),
//                 SizedBox(height: context.h(4)),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.baseline,
//                   textBaseline: TextBaseline.alphabetic,
//                   children: [
//                     if (hasLiveDiscount) ...[
//                       Text(
//                         '₹${pricer!.grossAmount.toStringAsFixed(0)}',
//                         style: TextStyle(
//                           fontSize: context.fs(11),
//                           color: const Color(0xff9CA3AF),
//                           decoration: TextDecoration.lineThrough,
//                         ),
//                       ),
//                       SizedBox(width: context.w(6)),
//                     ],
//                     Text(
//                       '₹${displayAmount.toStringAsFixed(0)}',
//                       style: TextStyle(fontSize: context.fs(17), fontWeight: FontWeight.w800, color: const Color(0xff0F172A)),
//                     ),
//                     SizedBox(width: context.w(4)),
//                     Text(
//                       '/ person',
//                       style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w600, color: const Color(0xff64748B)),
//                     ),
//                     if (stillLoading) ...[
//                       SizedBox(width: context.w(6)),
//                       SizedBox(
//                         width: context.w(10),
//                         height: context.w(10),
//                         child: const CircularProgressIndicator(strokeWidth: 1.6),
//                       ),
//                     ],
//                   ],
//                 ),
//                 SizedBox(height: context.h(8)),
//                 _dashedDivider(context, color: const Color(0xffE5E7EB)),
//                 SizedBox(height: context.h(9)),
//                 _fareSection(
//                   context,
//                   icon: Icons.luggage_outlined,
//                   iconColor: const Color(0xffEA580C),
//                   title: 'Baggage',
//                   lines: pricer != null
//                       ? ['Check-in : $checkinBaggageText', 'Cabin : $cabinBaggageText']
//                       : (stillLoading ? const ['Checking…'] : const ['As per airline policy']),
//                 ),
//                 SizedBox(height: context.h(9)),
//                 _fareSection(
//                   context,
//                   icon: Icons.sync_alt,
//                   iconColor: const Color(0xff2563EB),
//                   title: 'Flexibility',
//                   lines: stillLoading
//                       ? const ['Checking…', 'Checking…']
//                       : [
//                           'Cancellation : ${cancelFee ?? (option.refundable ? 'Refundable' : 'Non-refundable')}',
//                           'Date change : ${changeFee ?? 'Confirmed at next step'}',
//                         ],
//                   // Neither line resolved to a real fee figure — fall back to
//                   // a tap-through to the full fare-rule text instead of just
//                   // showing generic labels with no way to see the source.
//                   onTap: (!stillLoading && cancelFee == null && changeFee == null)
//                       ? () => _openFareRules(context, option)
//                       : null,
//                 ),
//                 SizedBox(height: context.h(9)),
//                 _fareSection(
//                   context,
//                   icon: Icons.restaurant_outlined,
//                   iconColor: const Color(0xff6B7280),
//                   title: 'Seat & meal',
//                   lines: const ['Chosen on the next step'],
//                   trailing: (seatsLeft != null && seatsLeft <= 9) ? 'Only $seatsLeft seats left' : null,
//                 ),
//               ],
//             ),
//           ),
//           if (isCheapest)
//             Positioned(
//               top: -context.h(9),
//               left: context.w(12),
//               child: _pillBadge(context, 'Lowest price', background: const Color(0xff0F2444), textColor: Colors.white),
//             ),
//           if (selected)
//             Positioned(
//               top: -context.h(9),
//               right: context.w(12),
//               child: Container(
//                 width: context.w(20),
//                 height: context.w(20),
//                 decoration: const BoxDecoration(color: Color(0xff16A34A), shape: BoxShape.circle),
//                 child: Icon(Icons.check, size: context.w(12), color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   /// Icon-labeled detail block (Baggage / Flexibility / Seat & meal) — mirrors
//   /// the web modal's `fareSection` styling instead of the old flat
//   /// label:value row list.
//   Widget _fareSection(
//       BuildContext context, {
//         required IconData icon,
//         required Color iconColor,
//         required String title,
//         required List<String> lines,
//         String? trailing,
//         VoidCallback? onTap,
//       }) {
//     final content = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: context.w(15), color: iconColor),
//             SizedBox(width: context.w(6)),
//             Text(
//               title,
//               style: TextStyle(fontSize: context.fs(11.5), fontWeight: FontWeight.w800, color: const Color(0xff111827)),
//             ),
//           ],
//         ),
//         SizedBox(height: context.h(3)),
//         for (final line in lines)
//           Padding(
//             padding: EdgeInsets.only(top: context.h(1)),
//             child: Text(
//               line,
//               style: TextStyle(
//                 fontSize: context.fs(10.5),
//                 fontWeight: FontWeight.w600,
//                 color: onTap != null ? const Color(0xff1663F7) : const Color(0xff374151),
//                 decoration: onTap != null ? TextDecoration.underline : null,
//               ),
//             ),
//           ),
//         if (trailing != null)
//           Padding(
//             padding: EdgeInsets.only(top: context.h(2)),
//             child: Text(
//               trailing,
//               style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w800, color: const Color(0xffDC2626)),
//             ),
//           ),
//       ],
//     );
//     return onTap != null
//         ? InkWell(borderRadius: BorderRadius.circular(context.r(6)), onTap: onTap, child: content)
//         : content;
//   }
//
//   Widget _pillBadge(BuildContext context, String text, {required Color background, required Color textColor}) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: context.w(9), vertical: context.h(3)),
//       decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
//       child: Text(
//         text,
//         style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.2),
//       ),
//     );
//   }
//
//   /// Best-effort extraction of a fee value from FareRule's free-text rule
//   /// lines (the API doc doesn't pin down a structured fee field — see
//   /// AKFareRule_model.dart's own comment on this). Prefers a currency
//   /// amount; when a line matches the keyword but carries no amount (real
//   /// responses can say e.g. "Non Refundable" instead of a ₹ figure), falls
//   /// back to that short verdict text. Returns null only when no line
//   /// matches any keyword at all, so the caller can fall back to a
//   /// "View fare rules" link instead of showing a wrong or missing value.
//   String? _extractFeeText(List<String> ruleTexts, List<String> keywords) {
//     for (final line in ruleTexts) {
//       final lower = line.toLowerCase();
//       if (!keywords.any((k) => lower.contains(k))) continue;
//
//       final match = RegExp(r'(₹|INR|Rs\.?)\s?[\d,]+(\.\d+)?').firstMatch(line);
//       if (match != null) return '${match.group(0)} onwards';
//
//       final parts = line.split('—').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
//       if (parts.isNotEmpty && parts.last.length <= 40) return parts.last;
//     }
//     return null;
//   }
//
//   void _openFareRules(BuildContext context, FareFamilyIndexEntity option) {
//     // This card's own GetSPricer-confirmed total once available, else its
//     // search-time amount.
//     final pricer = _cardPreviews[option.index]?.pricer;
//     final amount = (pricer != null && pricer.netAmount > 0) ? pricer.netAmount : option.amount;
//     AkFareRulePopup.show(
//       context,
//       searchTui: widget.tui,
//       resultIndex: option.index,
//       amount: amount,
//     );
//   }
//
//   Widget _amenities(BuildContext context, bool isFullyRefundable, int seatsLeft) {
//     return Row(
//       children: [
//         Expanded(
//           child: _infoCard(
//             context,
//             icon: Icons.event_seat_outlined,
//             iconColor: const Color(0xff9B5DE5),
//             title: 'Seats Left',
//             subtitle: seatsLeft > 0 ? '$seatsLeft seats at this fare' : 'Limited availability',
//           ),
//         ),
//         SizedBox(width: context.w(8)),
//         Expanded(
//           child: _infoCard(
//             context,
//             icon: isFullyRefundable ? Icons.verified_outlined : Icons.block_outlined,
//             iconColor: isFullyRefundable ? const Color(0xff16A34A) : const Color(0xffB42318),
//             title: 'Flexibility',
//             subtitle: isFullyRefundable ? 'Refundable fare' : 'Non-refundable fare',
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _infoCard(
//       BuildContext context, {
//         required IconData icon,
//         required Color iconColor,
//         required String title,
//         required String subtitle,
//       }) {
//     return Container(
//       padding: EdgeInsets.all(context.w(10)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.r(14)),
//         border: Border.all(color: const Color(0xffE6ECFF)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: context.w(26),
//             height: context.w(26),
//             decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
//             child: Icon(icon, color: iconColor, size: context.w(14)),
//           ),
//           SizedBox(width: context.w(7)),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: const Color(0xff07163B),
//                     fontSize: context.fs(11),
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 SizedBox(height: context.h(2)),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     color: const Color(0xff7C849F),
//                     fontSize: context.fs(9),
//                     fontWeight: FontWeight.w500,
//                     height: 1.25,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _features(BuildContext context) {
//     final items = [
//       (Icons.lock_outline, 'Trusted Booking', '100% Secure'),
//       (Icons.headphones, '24/7 Support', "We're here to help"),
//       (Icons.sync_alt, 'Easy Changes', 'Hassle-free'),
//       (Icons.verified_outlined, 'Best Price', 'Best deals'),
//     ];
//
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.w(10)),
//       decoration: BoxDecoration(
//         color: const Color(0xffFFFDF2),
//         borderRadius: BorderRadius.circular(context.r(14)),
//         border: Border.all(color: const Color(0xffFDE68A)),
//       ),
//       child: Wrap(
//         spacing: context.w(12),
//         runSpacing: context.h(8),
//         children: items
//             .map(
//               (item) => SizedBox(
//             width: context.w(130),
//             child: Row(
//               children: [
//                 Icon(item.$1, color: const Color(0xffF59E0B), size: context.w(13)),
//                 SizedBox(width: context.w(5)),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item.$2,
//                         style: TextStyle(
//                           color: const Color(0xff07163B),
//                           fontSize: context.fs(9),
//                           fontWeight: FontWeight.w800,
//                         ),
//                       ),
//                       Text(
//                         item.$3,
//                         style: TextStyle(
//                           color: const Color(0xff7C849F),
//                           fontSize: context.fs(8),
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         )
//             .toList(),
//       ),
//     );
//   }
//
//   Widget _bottomBar(
//       BuildContext context,
//       AkFlightInfoEntity data,
//       AkFlightInfoJourneyEntity journey,
//       AkFlightInfoFlightEntity firstFlight,
//       AkFlightInfoFlightEntity lastFlight,
//       bool isFullyRefundable,
//       bool fareChanged,
//       ) {
//     final bookingReady = _sessionId != null && _pricingTui != null && !_switchingFare && !_committing;
//     return Row(
//       children: [
//         Expanded(
//           child: Row(
//             children: [
//               Icon(
//                 isFullyRefundable ? Icons.verified_user_outlined : Icons.info_outline,
//                 color: isFullyRefundable ? const Color(0xff16A34A) : const Color(0xff9CA3AF),
//                 size: context.w(15),
//               ),
//               SizedBox(width: context.w(6)),
//               Expanded(
//                 child: RichText(
//                   text: TextSpan(
//                     children: [
//                       TextSpan(
//                         text: isFullyRefundable ? 'Free cancellation ' : 'Non-refundable fare ',
//                         style: TextStyle(
//                           color: isFullyRefundable ? const Color(0xff16A34A) : const Color(0xff6B7280),
//                           fontWeight: FontWeight.w800,
//                           fontSize: context.fs(9),
//                         ),
//                       ),
//                       TextSpan(
//                         text: 'as per airline policy',
//                         style: TextStyle(
//                           color: const Color(0xff4B5563),
//                           fontWeight: FontWeight.w500,
//                           fontSize: context.fs(9),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(width: context.w(10)),
//         SizedBox(
//           height: context.h(42),
//           child: ElevatedButton(
//             onPressed: bookingReady
//                 ? () => _handleBookNow(
//               context,
//               data,
//               journey,
//               firstFlight,
//               lastFlight,
//               isFullyRefundable,
//               fareChanged,
//             )
//                 : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xff1663F7),
//               foregroundColor: Colors.white,
//               disabledBackgroundColor: const Color(0xffA0A6C2),
//               elevation: 0,
//               padding: EdgeInsets.symmetric(horizontal: context.w(18)),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
//             ),
//             child: bookingReady
//                 ? Text(
//               'Book Now',
//               style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w800),
//             )
//                 : SizedBox(
//               width: context.w(16),
//               height: context.w(16),
//               child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// Gates "Book Now" on the fare-change consent flow: if GetSPricer flagged
//   /// `fareChanged`, the doc requires showing the new fare, getting explicit
//   /// consent, and calling AcceptFareChange before CreateItinerary is allowed
//   /// to run later in the booking screen.
//   Future<void> _handleBookNow(
//       BuildContext context,
//       AkFlightInfoEntity data,
//       AkFlightInfoJourneyEntity journey,
//       AkFlightInfoFlightEntity firstFlight,
//       AkFlightInfoFlightEntity lastFlight,
//       bool isFullyRefundable,
//       bool fareChanged,
//       ) async {
//     if (fareChanged && !_fareChangeAccepted) {
//       final accepted = await _confirmFareChange(context, data.netAmount);
//       if (!accepted) return;
//       _fareChangeAccepted = true;
//     }
//     if (!context.mounted) return;
//
//     final committed = await _commitPricing();
//     if (!committed) return;
//     if (!context.mounted) return;
//
//     _bookNow(context, data, journey, firstFlight, lastFlight, isFullyRefundable);
//   }
//
//   /// Final, non-preview SmartPricer -> GetSPricer commit. Every SmartPricer/
//   /// GetSPricer call made while the user was browsing this sheet (initial
//   /// load, fare switches) runs with `preview: true`, which by design never
//   /// writes `session.pricing_tui` server-side (see [_loadSmartPricer]) — so
//   /// without this step, CreateItinerary (called next, from the booking
//   /// screen) 400s with "This session has not been priced yet". This re-runs
//   /// the same chain with `preview: false` right before navigating on, so the
//   /// session is actually priced by the time booking details are submitted.
//   Future<bool> _commitPricing() async {
//     setState(() => _committing = true);
//
//     _smartPricerBloc.add(LoadAkSmartPricerEvent(
//       AkSmartPricerRequestEntity(
//         searchTui: widget.tui,
//         tripType: widget.tripType,
//         trips: [
//           AkSmartPricerTripRequestEntity(index: _selectedIndex, amount: _selectedAmount, orderId: 1),
//           for (final leg in widget.additionalLegs)
//             AkSmartPricerTripRequestEntity(index: leg.resultIndex, amount: leg.amount, orderId: leg.orderId),
//         ],
//         preview: false,
//       ),
//     ));
//
//     final smartPricerState = await _smartPricerBloc.stream.firstWhere(
//       (s) => s is AkSmartPricerLoaded || s is AkSmartPricerFailed,
//     );
//     if (smartPricerState is! AkSmartPricerLoaded) {
//       if (mounted) {
//         setState(() => _committing = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not confirm this fare. Please try again.')),
//         );
//       }
//       return false;
//     }
//     _sessionId = smartPricerState.data.sessionId;
//
//     _pricerBloc.add(LoadAkGetSPricerEvent(
//       AkGetSPricerRequestEntity(tui: smartPricerState.data.tui, preview: false),
//     ));
//
//     final pricerState = await _pricerBloc.stream.firstWhere(
//       (s) => s is AkGetSPricerLoaded || s is AkGetSPricerFailed,
//     );
//     if (pricerState is! AkGetSPricerLoaded) {
//       if (mounted) {
//         setState(() => _committing = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not confirm this fare. Please try again.')),
//         );
//       }
//       return false;
//     }
//     _pricingTui = pricerState.data.tui;
//     _pricerData = pricerState.data;
//
//     if (mounted) setState(() => _committing = false);
//     return true;
//   }
//
//   Future<bool> _confirmFareChange(BuildContext context, double newAmount) async {
//     final wantsToContinue = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Fare Updated'),
//         content: Text(
//           'The price for this flight has changed to ${_formatAmount(newAmount)}. '
//               'Do you want to continue with the new fare?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(dialogContext, true),
//             child: const Text('Accept & Continue'),
//           ),
//         ],
//       ),
//     );
//     if (wantsToContinue != true || _sessionId == null) return false;
//
//     final result = await sl<AkAcceptFareChangeUseCase>().call(
//       AkAcceptFareChangeRequestEntity(sessionId: _sessionId!),
//     );
//     if (result is DataSuccess<AkAcceptFareChangeEntity> && result.data?.success == true) {
//       return true;
//     }
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not confirm the new fare. Please try again.')),
//       );
//     }
//     return false;
//   }
//
//   Widget _airlineBadge(BuildContext context, String code, String name, {required double size}) {
//     final logoCode = code.trim().toUpperCase();
//     final initials = _displayAirlineCode(logoCode.isNotEmpty ? logoCode : name);
//
//     Widget initialsTile() => Container(
//       color: _airlineColor(initials),
//       alignment: Alignment.center,
//       child: Text(
//         initials,
//         style: TextStyle(color: Colors.white, fontSize: context.fs(9), fontWeight: FontWeight.w900),
//       ),
//     );
//
//     return Container(
//       width: size,
//       height: size,
//       clipBehavior: Clip.antiAlias,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.r(8)),
//         border: Border.all(color: const Color(0xffE6ECFF)),
//       ),
//       child: logoCode.isEmpty
//           ? initialsTile()
//           : Padding(
//         padding: EdgeInsets.all(context.w(3)),
//         child: CachedNetworkImage(
//           imageUrl: 'https://images.kiwi.com/airlines/64/$logoCode.png',
//           fit: BoxFit.contain,
//           placeholder: (_, __) => initialsTile(),
//           errorWidget: (_, __, ___) => initialsTile(),
//         ),
//       ),
//     );
//   }
//
//   void _bookNow(
//       BuildContext context,
//       AkFlightInfoEntity data,
//       AkFlightInfoJourneyEntity journey,
//       AkFlightInfoFlightEntity firstFlight,
//       AkFlightInfoFlightEntity lastFlight,
//       bool isFullyRefundable,
//       ) {
//     final totalPrice = _formatAmount(data.netAmount);
//     Navigator.pop(context);
//
//     // Legs beyond the first (return leg for RT/RS, legs 2..N for Multi
//     // City) — each is its own confirmed AkFlightInfo trip/journey, since
//     // FlightInfo/SmartPricer/GetSPricer were sent every leg's index/orderId,
//     // not just the first.
//     final additionalLegRoutes = data.trips.length > 1
//         ? data.trips
//             .sublist(1)
//             .where((trip) => trip.journey.isNotEmpty && trip.journey.first.segments.isNotEmpty)
//             .map((trip) {
//               final legJourney = trip.journey.first;
//               final legSegments = legJourney.segments;
//               final legFirstFlight = legSegments.first.flight;
//               final legLastFlight = legSegments.last.flight;
//               return FlightRouteSegment(
//                 from: legFirstFlight.departureCode,
//                 to: legLastFlight.arrivalCode,
//                 departureTime: _formatApiTime(legFirstFlight.departureTime),
//                 arrivalTime: _formatApiTime(legLastFlight.arrivalTime),
//                 departureDate: _formatApiDate(legFirstFlight.departureTime),
//                 duration: _cleanDuration(legJourney.duration),
//                 airline: _marketingSegment(legFirstFlight.airline, fallback: legFirstFlight.airline),
//                 flightNo: "${_airlineCodeOf(legFirstFlight)} • ${legFirstFlight.flightNo}",
//                 price: _formatAmount(legJourney.netFare),
//                 stops: legJourney.stops,
//                 viaAirports: _viaAirportsOf(legSegments),
//                 isRefundable: legSegments.every((s) => s.flight.refundable.toUpperCase() == 'Y'),
//                 searchTui: widget.tui,
//                 pricingTui: _pricingTui,
//                 sessionId: _sessionId,
//                 amount: legJourney.netFare,
//               );
//             })
//             .toList()
//         : const <FlightRouteSegment>[];
//
//     final route = FlightRouteSegment(
//       from: firstFlight.departureCode,
//       to: lastFlight.arrivalCode,
//       price: totalPrice,
//       traceId: widget.traceId,
//       resultIndex: widget.resultIndex,
//       departureTime: _formatApiTime(firstFlight.departureTime),
//       arrivalTime: _formatApiTime(lastFlight.arrivalTime),
//       departureDate: _formatApiDate(firstFlight.departureTime),
//       duration: _cleanDuration(journey.duration),
//       airline: _marketingSegment(firstFlight.airline, fallback: widget.airlineName),
//       flightNo: "${_airlineCodeOf(firstFlight)} • ${firstFlight.flightNo}",
//       stops: journey.stops,
//       viaAirports: _viaAirportsOf(journey.segments),
//       isRefundable: isFullyRefundable,
//       searchTui: widget.tui,
//       pricingTui: _pricingTui,
//       sessionId: _sessionId,
//       // The currently selected fare family's confirmed amount, not
//       // necessarily widget.amount (the originally tapped card) — the user
//       // may have switched fares via the selector above.
//       amount: data.netAmount > 0 ? data.netAmount : widget.amount,
//       akFareData: _pricerData,
//     );
//
//     final pricer = _pricerData;
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SeatAddonsScreen(
//           route: route,
//           totalPrice: totalPrice,
//           traceId: widget.traceId,
//           resultIndex: widget.resultIndex,
//           price: totalPrice,
//           travellerCount: widget.travellerCount,
//           adultCount: pricer?.adultCount ?? 0,
//           childCount: pricer?.childCount ?? 0,
//           infantCount: pricer?.infantCount ?? 0,
//           additionalLegs: additionalLegRoutes,
//         ),
//       ),
//     );
//   }
//
//   // ---------------------------------------------------------------------------
//   // Formatting helpers
//   // ---------------------------------------------------------------------------
//
//   /// Prefers the real marketing carrier code (MAC) over VAC, matching the
//   /// convention used for the search results list.
//   String _airlineCodeOf(AkFlightInfoFlightEntity flight) =>
//       flight.mac.isNotEmpty ? flight.mac : flight.vac;
//
//   /// The connecting airport(s) between segments of a multi-segment (stopover)
//   /// journey — every segment's arrival code except the last, since the last
//   /// segment's arrival is the journey's final destination, not a stop.
//   List<String> _viaAirportsOf(List<AkFlightInfoSegmentEntity> segments) {
//     if (segments.length <= 1) return const [];
//     return segments
//         .sublist(0, segments.length - 1)
//         .map((s) => s.flight.arrivalCode)
//         .toList();
//   }
//
//   /// "Air India|Air India|Air India Express IX" -> "Air India" (marketing
//   /// carrier name, aligned with the MAC code position).
//   String _marketingSegment(String value, {required String fallback}) {
//     final parts = value.split('|').map((p) => p.trim()).toList();
//     if (parts.length > 1 && parts[1].isNotEmpty) return parts[1];
//     final firstNonEmpty = parts.firstWhere((p) => p.isNotEmpty, orElse: () => '');
//     return firstNonEmpty.isNotEmpty ? firstNonEmpty : fallback;
//   }
//
//   /// "Bengaluru International Airport |Bangalore" -> "Bangalore"
//   String _lastSegment(String value) {
//     final parts = value.split('|');
//     final last = parts.last.trim();
//     return last.isNotEmpty ? last : value.trim();
//   }
//
//   String _formatApiTime(String isoTime) {
//     if (isoTime.isEmpty) return '--:--';
//     try {
//       final dt = DateTime.parse(isoTime);
//       return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
//     } catch (_) {
//       return isoTime;
//     }
//   }
//
//   /// "2026-08-01T10:30:00" -> "01 Aug 2026", for display on the ticket
//   /// confirmation screen (departureTime only carries the time-of-day).
//   String _formatApiDate(String isoTime) {
//     if (isoTime.isEmpty) return '';
//     try {
//       return DateFormat('dd MMM yyyy').format(DateTime.parse(isoTime));
//     } catch (_) {
//       return '';
//     }
//   }
//
//   /// "01h 25m " -> "1h 25m"
//   String _cleanDuration(String duration) {
//     final hours = int.tryParse(RegExp(r'(\d+)h').firstMatch(duration)?.group(1) ?? '') ?? 0;
//     final minutes = int.tryParse(RegExp(r'(\d+)m').firstMatch(duration)?.group(1) ?? '') ?? 0;
//     if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
//     if (hours > 0) return '${hours}h';
//     if (minutes > 0) return '${minutes}m';
//     return duration.trim();
//   }
//
//   String? _layoverLabel(String arrivalIso, String departureIso) {
//     try {
//       final arrival = DateTime.parse(arrivalIso);
//       final departure = DateTime.parse(departureIso);
//       final gap = departure.difference(arrival);
//       if (gap.isNegative) return null;
//       final h = gap.inHours;
//       final m = gap.inMinutes % 60;
//       if (h > 0 && m > 0) return '${h}h ${m}m';
//       if (h > 0) return '${h}h';
//       return '${m}m';
//     } catch (_) {
//       return null;
//     }
//   }
//
//   String _formatAmount(double amount) {
//     final rounded = amount.round();
//     final str = rounded.toString();
//     if (str.length <= 3) return '₹$str';
//     final last3 = str.substring(str.length - 3);
//     final remaining = str.substring(0, str.length - 3);
//     var formatted = '';
//     for (int i = 0; i < remaining.length; i++) {
//       if (i > 0 && (remaining.length - i) % 2 == 0) formatted += ',';
//       formatted += remaining[i];
//     }
//     return '₹$formatted,$last3';
//   }
//
//   String _displayAirlineCode(String value) {
//     final letters = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
//     if (letters.length >= 2) return letters.substring(0, 2);
//     return letters.isEmpty ? 'FL' : letters;
//   }
//
//   Color _airlineColor(String code) {
//     final colors = [
//       const Color(0xffC29200),
//       const Color(0xff25358D),
//       const Color(0xff7A003C),
//       const Color(0xff0F766E),
//       const Color(0xffB42318),
//     ];
//     final hash = code.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
//     return colors[hash % colors.length];
//   }
//
//   // ---------------------------------------------------------------------------
//   // Shared ticket-style pieces (unchanged look & feel from the original design)
//   // ---------------------------------------------------------------------------
//   Widget _timeBlock(BuildContext context, String time, String code, bool alignRight) {
//     return SizedBox(
//       width: context.w(62),
//       child: Column(
//         crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Text(
//             time,
//             style: TextStyle(
//               color: const Color(0xff3D3F4A),
//               fontSize: context.fs(19),
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//           SizedBox(height: context.h(3)),
//           Text(
//             code,
//             style: TextStyle(
//               color: const Color(0xffA0A6C2),
//               fontSize: context.fs(11),
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _flightPath(BuildContext context) {
//     const color = Color(0xff5F86FF);
//     return Row(
//       children: [
//         _pathDot(context, color),
//         Expanded(
//           child: CustomPaint(
//             painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
//             child: SizedBox(height: context.h(1)),
//           ),
//         ),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: context.w(4)),
//           child: Icon(Icons.flight, color: color, size: context.w(20)),
//         ),
//         Expanded(
//           child: CustomPaint(
//             painter: _DashedLinePainter(color: const Color(0xffDDE3EF)),
//             child: SizedBox(height: context.h(1)),
//           ),
//         ),
//         _pathDot(context, color),
//       ],
//     );
//   }
//
//   Widget _pathDot(BuildContext context, Color color) {
//     return Container(
//       width: context.w(7),
//       height: context.w(7),
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: color,
//         boxShadow: [
//           BoxShadow(color: color.withValues(alpha: 0.26), blurRadius: context.w(6), spreadRadius: context.w(1)),
//         ],
//       ),
//     );
//   }
//
//   Widget _dashedDivider(BuildContext context, {Color color = const Color(0xffDDE3EF)}) {
//     return CustomPaint(
//       painter: _DashedLinePainter(color: color),
//       child: SizedBox(width: double.infinity, height: context.h(1)),
//     );
//   }
//
//   Widget _metaChip(BuildContext context, String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(color: const Color(0xffA0A6C2), fontSize: context.fs(9), fontWeight: FontWeight.w600),
//         ),
//         SizedBox(height: context.h(3)),
//         Container(
//           padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(context.r(12)),
//             border: Border.all(color: const Color(0xffE6ECFF)),
//           ),
//           child: Text(
//             value,
//             style: TextStyle(color: const Color(0xff3D3F4A), fontSize: context.fs(10), fontWeight: FontWeight.w700),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _DashedLinePainter extends CustomPainter {
//   final Color color;
//
//   _DashedLinePainter({required this.color});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = 1.2
//       ..strokeCap = StrokeCap.round;
//     const dashWidth = 6.0;
//     const dashSpace = 6.0;
//     var startX = 0.0;
//     final y = size.height / 2;
//
//     while (startX < size.width) {
//       canvas.drawLine(
//         Offset(startX, y),
//         Offset(math.min(startX + dashWidth, size.width), y),
//         paint,
//       );
//       startX += dashWidth + dashSpace;
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
//     return oldDelegate.color != color;
//   }
// }
//
// class _DetailTicketPainter extends CustomPainter {
//   final Color color;
//   final Color shadowColor;
//
//   _DetailTicketPainter({required this.color, required this.shadowColor});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     const notchRadius = 13.0;
//     const radius = 18.0;
//     final notchY = size.height * 0.62;
//     final rect = Rect.fromLTWH(0, 0, size.width, size.height);
//     final path = Path()
//       ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(radius)));
//     final leftNotch = Path()
//       ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: notchRadius));
//     final rightNotch = Path()
//       ..addOval(Rect.fromCircle(center: Offset(size.width, notchY), radius: notchRadius));
//     final cutLeft = Path.combine(PathOperation.difference, path, leftNotch);
//     final ticket = Path.combine(PathOperation.difference, cutLeft, rightNotch);
//
//     canvas.drawShadow(ticket, shadowColor, 12, true);
//     canvas.drawPath(ticket, Paint()..color = color);
//     canvas.drawPath(
//       ticket,
//       Paint()
//         ..color = const Color(0xffE6ECFF)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant _DetailTicketPainter oldDelegate) {
//     return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
//   }
// }

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
  final List<FareFamilyIndexEntity>? fareFamilyOptions;
  final String tripType;
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

class _FlightDetailsPopupState extends State<FlightDetailsPopup> with SingleTickerProviderStateMixin {
  late final AkFlightInfoBloc _bloc;
  late final AkSmartPricerBloc _smartPricerBloc;
  late final AkGetSPricerBloc _pricerBloc;
  late final AkFareRuleBloc _fareRuleBloc;

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
  }

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
    });
    _load();
    _loadFareRule();
  }

  @override
  void dispose() {
    _expansionController.dispose();
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
        child: FadeTransition(
          opacity: _expansionAnimation,
          child: Padding(
            padding: EdgeInsets.only(
              left: context.w(10),
              right: context.w(10),
              bottom: MediaQuery.of(context).viewInsets.bottom + context.h(8),
            ),
            child: Container(
              constraints: BoxConstraints(maxHeight: context.screenHeight * 0.92),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(28))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: context.w(30),
                    offset: Offset(0, -context.h(8)),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(28))),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(16),
                      context.h(12),
                      context.w(16),
                      context.h(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dragHandle(context),
                        SizedBox(height: context.h(12)),
                        _header(context),
                        SizedBox(height: context.h(16)),
                        if (widget.additionalLegs.isNotEmpty) ...[
                          _additionalLegsSummary(context),
                          SizedBox(height: context.h(12)),
                        ],
                        if (_fareOptions.length > 1) ...[
                          _fareSelector(context),
                          SizedBox(height: context.h(14)),
                        ],
                        _mainContent(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dragHandle(BuildContext context) {
    return Container(
      width: context.w(40),
      height: context.h(4),
      decoration: BoxDecoration(
        color: const Color(0xffCBD5E1),
        borderRadius: BorderRadius.circular(context.r(4)),
      ),
    );
  }

  // ==================== MODERN HEADER ====================
  Widget _header(BuildContext context) {
    return Row(
      children: [
        _airlineLogo(context, widget.airlineCode, widget.airlineName, size: context.w(44)),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.airlineName,
                style: TextStyle(
                  color: const Color(0xff1E293B),
                  fontSize: context.fs(15),
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Text(
                    widget.flightNumber,
                    style: TextStyle(
                      color: const Color(0xff64748B),
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    width: context.w(4),
                    height: context.w(4),
                    margin: EdgeInsets.symmetric(horizontal: context.w(6)),
                    decoration: const BoxDecoration(
                      color: Color(0xff94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    // NOT `_formatDate(widget.departureTime)` — by the time it
                    // reaches this popup, widget.departureTime has already
                    // been reduced to just "HH:mm" by the caller (see
                    // flight_search_screen.dart's `_formatTime(flight.departureTime)`),
                    // so _formatDate (which re-parses it as a full ISO date)
                    // always throws and silently renders an empty string here.
                    // The route is real data we do have, so show that instead.
                    '${widget.fromCode} → ${widget.toCode}',
                    style: TextStyle(
                      color: const Color(0xff64748B),
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(context.r(20)),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: context.w(32),
            height: context.w(32),
            decoration: BoxDecoration(
              color: const Color(0xffF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: const Color(0xff475569),
              size: context.w(16),
            ),
          ),
        ),
      ],
    );
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
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: const Color(0xffE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withValues(alpha: 0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                // widget.departureTime/arrivalTime are already formatted
                // "HH:mm" strings by the caller — NOT raw ISO timestamps — so
                // they're used as-is here, unlike `_formatTime(firstFlight...)`
                // in the loaded route card below which parses real API data.
                child: _timeLocation(context, time: widget.departureTime, code: widget.fromCode, name: ''),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(height: context.h(2), color: const Color(0xff3B82F6)),
                    SizedBox(height: context.h(4)),
                    Text(
                      widget.duration,
                      style: TextStyle(
                        color: const Color(0xff64748B),
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _timeLocation(
                  context,
                  time: widget.arrivalTime,
                  code: widget.toCode,
                  name: '',
                  alignRight: true,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              // No calendar-date chip here — unlike the loaded route card
              // below, the raw ISO departure timestamp was already reduced
              // to just "HH:mm" by the caller before reaching this widget
              // (see the header fix above), so there's no real date to show
              // yet. Only genuinely-known fields are shown until FlightInfo
              // resolves.
              _infoChip(context, Icons.schedule, widget.duration, size: context.w(12)),
              SizedBox(width: context.w(8)),
              _infoChip(context, Icons.sell_outlined, widget.price, size: context.w(12)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== FLIGHT ROUTE CARD ====================
  Widget _flightRouteCard(BuildContext context, AkFlightInfoEntity data) {
    final journey = data.trips.isNotEmpty && data.trips.first.journey.isNotEmpty
        ? data.trips.first.journey.first
        : null;

    if (journey == null || journey.segments.isEmpty) {
      return _emptyState(context);
    }

    final segments = journey.segments;
    final firstFlight = segments.first.flight;
    final lastFlight = segments.last.flight;

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: const Color(0xffE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withValues(alpha: 0.04),
            blurRadius: context.w(12),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          // Time & Route
          Row(
            children: [
              Expanded(
                child: _timeLocation(
                  context,
                  time: _formatTime(firstFlight.departureTime),
                  code: firstFlight.departureCode,
                  name: _shortCityName(firstFlight.depAirportName),
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
                  code: lastFlight.arrivalCode,
                  name: _shortCityName(lastFlight.arrAirportName),
                  alignRight: true,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          // Flight details row
          Row(
            children: [
              _infoChip(context, Icons.calendar_today, _formatDate(widget.departureTime), size: context.w(12)),
              SizedBox(width: context.w(8)),
              _infoChip(context, Icons.flight_takeoff, '${segments.length - 1} stop${segments.length > 2 ? 's' : ''}', size: context.w(12)),
              SizedBox(width: context.w(8)),
              _infoChip(context, Icons.schedule, _cleanDuration(journey.duration), size: context.w(12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeLocation(BuildContext context, {
    required String time,
    required String code,
    required String name,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            color: const Color(0xff0F172A),
            fontSize: context.fs(20),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.h(2)),
        Text(
          code,
          style: TextStyle(
            color: const Color(0xff475569),
            fontSize: context.fs(13),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: context.h(2)),
        Text(
          name,
          style: TextStyle(
            color: const Color(0xff94A3B8),
            fontSize: context.fs(10),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _flightPathWithStops(BuildContext context, List<AkFlightInfoSegmentEntity> segments, {required String duration}) {
    final isDirect = segments.length == 1;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: context.h(2),
                decoration: BoxDecoration(
                  // `colors` and `stops` must be the same length (Flutter
                  // asserts this) — the 3-stop gradient needs 3 colors, not 2,
                  // or every connecting (non-direct) flight throws here.
                  gradient: LinearGradient(
                    colors: isDirect
                        ? const [Color(0xff3B82F6), Color(0xff3B82F6)]
                        : const [Color(0xff3B82F6), Color(0xff3B82F6), Color(0xff94A3B8)],
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
                  height: context.h(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xff94A3B8),
                        const Color(0xff3B82F6),
                      ],
                      stops: const [0, 1],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: context.h(4)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              duration,
              style: TextStyle(
                color: const Color(0xff64748B),
                fontSize: context.fs(10),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isDirect)
              Text(
                '${_shortCityName(segments.first.flight.arrAirportName)}',
                style: TextStyle(
                  color: const Color(0xff94A3B8),
                  fontSize: context.fs(9),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ==================== MODERN FARE SELECTOR - FIXED ====================
  Widget _fareSelector(BuildContext context) {
    final sorted = [..._fareOptions]..sort((a, b) => a.amount.compareTo(b.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Select Fare',
              style: TextStyle(
                color: const Color(0xff1E293B),
                fontSize: context.fs(14),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: context.w(8)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(2)),
              decoration: BoxDecoration(
                color: const Color(0xffEFF6FF),
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
              child: Text(
                '${sorted.length} options',
                style: TextStyle(
                  color: const Color(0xff3B82F6),
                  fontSize: context.fs(9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(10)),
        SizedBox(
          height: context.h(150), // Increased height for better touch targets
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => SizedBox(width: context.w(10)),
            itemBuilder: (_, i) => _fareCard(context, sorted[i], i, sorted.length),
          ),
        ),
      ],
    );
  }

  Widget _fareCard(BuildContext context, FareFamilyIndexEntity option, int rank, int total) {
    final selected = option.index == _selectedIndex;
    final isCheapest = rank == 0;

    Color getCardColor() {
      if (selected) return const Color(0xff1E40AF);
      if (isCheapest) return const Color(0xffF0FDF4);
      return Colors.white;
    }

    Color getBorderColor() {
      if (selected) return const Color(0xff1E40AF);
      if (isCheapest) return const Color(0xff22C55E);
      return const Color(0xffE2E8F0);
    }

    // Determine if this fare can be selected
    final bool canSelect = !selected && !_switchingFare;

    return GestureDetector(
      onTap: canSelect ? () => _selectFare(option) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: context.w(160),
        padding: EdgeInsets.all(context.w(14)),
        decoration: BoxDecoration(
          color: getCardColor(),
          borderRadius: BorderRadius.circular(context.r(14)),
          border: Border.all(
            color: getBorderColor(),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: const Color(0xff1E40AF).withValues(alpha: 0.15),
              blurRadius: context.w(12),
              offset: Offset(0, context.h(4)),
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getFareLabel(option, rank, total),
                        style: TextStyle(
                          color: selected ? Colors.white : const Color(0xff1E293B),
                          fontSize: context.fs(12),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCheapest)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(2)),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : const Color(0xff22C55E),
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                        child: Text(
                          'Best',
                          style: TextStyle(
                            color: selected ? const Color(0xff1E40AF) : Colors.white,
                            fontSize: context.fs(8),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: context.h(6)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${option.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xff0F172A),
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Text(
                      '/person',
                      style: TextStyle(
                        color: selected ? Colors.white.withValues(alpha: 0.7) : const Color(0xff94A3B8),
                        fontSize: context.fs(9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(6)),
                Row(
                  children: [
                    Icon(
                      option.refundable ? Icons.verified_outlined : Icons.info_outline,
                      color: selected ? Colors.white.withValues(alpha: 0.7) : const Color(0xff94A3B8),
                      size: context.w(12),
                    ),
                    SizedBox(width: context.w(4)),
                    Text(
                      option.refundable ? 'Refundable' : 'Non-refundable',
                      style: TextStyle(
                        color: selected ? Colors.white.withValues(alpha: 0.7) : const Color(0xff94A3B8),
                        fontSize: context.fs(9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: context.w(24),
                  height: context.w(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xff1E40AF),
                    size: 20,
                  ),
                ),
              ),
            // Add a subtle loading indicator if this fare is being switched
            if (_switchingFare && selected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(context.r(14)),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: context.w(20),
                      height: context.w(20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFareLabel(FareFamilyIndexEntity option, int rank, int total) {
    if (rank == 0) return 'Saver';
    if (rank == total - 1) return 'Flexi';
    return 'Standard';
  }

  // ==================== MAIN CONTENT ====================
  Widget _mainContent(BuildContext context) {
    return BlocBuilder<AkFlightInfoBloc, AkFlightInfoState>(
      builder: (context, flightInfoState) {
        if (flightInfoState is AkFlightInfoFailed) {
          return _errorState(context, flightInfoState.error.message ?? 'Failed to load flight details');
        }
        if (flightInfoState is AkFlightInfoLoaded) {
          return BlocBuilder<AkGetSPricerBloc, AkGetSPricerState>(
            builder: (context, pricerState) {
              if (pricerState is AkGetSPricerLoaded) {
                final merged = _mergeWithPricer(flightInfoState.data, pricerState.data);
                return _loadedContent(context, merged, pricerState.data);
              }
              return _loadedContent(context, flightInfoState.data);
            },
          );
        }
        // FlightInfo hasn't resolved yet — but the tapped search result
        // already told us the route/times/price (that's what widget.fromCode/
        // toCode/departureTime/arrivalTime/duration/price are for, per the
        // FlightDetailsPopup doc comment: "Shown immediately while FlightInfo
        // loads"). Show that now instead of a blank full-page spinner with
        // nothing on it.
        return _placeholderContent(context);
      },
    );
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

    return Column(
      children: [
        if (fareChanged) _fareChangedBanner(context),
        if (fareChanged) SizedBox(height: context.h(10)),
        _flightRouteCard(context, data),
        SizedBox(height: context.h(12)),
        _amenitiesSection(context, isFullyRefundable, journey, data, pricerData),
        SizedBox(height: context.h(12)),
        _baggageAndPolicy(context, pricerData, isFullyRefundable),
        SizedBox(height: context.h(16)),
        _bookButton(context, data, journey, isFullyRefundable, fareChanged),
      ],
    );
  }

  // ==================== AMENITIES SECTION ====================
  Widget _amenitiesSection(
      BuildContext context,
      bool isFullyRefundable,
      AkFlightInfoJourneyEntity journey,
      AkFlightInfoEntity data,
      AkGetSPricerEntity? pricerData,
      ) {
    final minSeats = journey.segments
        .map((s) => s.flight.seats)
        .fold<int>(1 << 30, (m, s) => s < m ? s : m);
    // Was hardcoded to always say "15 kg check-in" no matter what the fare
    // actually includes — real allowance varies by fare/airline (7/15/20/25
    // Kg are all seen live) and the correct value is already fetched for the
    // Baggage & Policy card below, so read it from there instead of faking it.
    final checkinBaggage = _checkinBaggageText(pricerData);

    final items = [
      {
        'icon': Icons.luggage_outlined,
        'color': const Color(0xff8B5CF6),
        'title': 'Baggage',
        'subtitle': 'Check-in: $checkinBaggage',
        'bgColor': const Color(0xffF5F3FF),
      },
      {
        'icon': isFullyRefundable ? Icons.verified_outlined : Icons.info_outline,
        'color': isFullyRefundable ? const Color(0xff22C55E) : const Color(0xffF59E0B),
        'title': isFullyRefundable ? 'Refundable' : 'Non-refundable',
        'subtitle': isFullyRefundable ? 'Free cancellation' : 'No cancellation',
        'bgColor': isFullyRefundable ? const Color(0xffF0FDF4) : const Color(0xffFFFBEB),
      },
      {
        'icon': Icons.event_seat_outlined,
        'color': minSeats > 5 ? const Color(0xff3B82F6) : const Color(0xffEF4444),
        'title': 'Seats',
        'subtitle': minSeats > 5 ? '${minSeats} seats left' : 'Only $minSeats left!',
        'bgColor': minSeats > 5 ? const Color(0xffEFF6FF) : const Color(0xffFEF2F2),
      },
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: context.w(6)),
            padding: EdgeInsets.all(context.w(10)),
            decoration: BoxDecoration(
              color: item['bgColor'] as Color,
              borderRadius: BorderRadius.circular(context.r(12)),
              border: Border.all(color: const Color(0xffF1F5F9), width: 1),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(context.w(6)),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: context.w(14),
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: const Color(0xff1E293B),
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item['subtitle'] as String,
                  style: TextStyle(
                    color: const Color(0xff64748B),
                    fontSize: context.fs(8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Shared by [_amenitiesSection] and [_baggageAndPolicy] so both read the
  /// same real GetSPricer baggage allowance instead of one of them faking it.
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
    return baggage != null && baggage.cabin.isNotEmpty ? '${baggage.cabin} kg' : 'As per airline';
  }

  // ==================== BAGGAGE & POLICY ====================
  Widget _baggageAndPolicy(BuildContext context, AkGetSPricerEntity? pricerData, bool isFullyRefundable) {
    final checkin = _checkinBaggageText(pricerData);
    final cabin = _cabinBaggageText(pricerData);

    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: const Color(0xffE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baggage',
                  style: TextStyle(
                    color: const Color(0xff475569),
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Row(
                  children: [
                    Icon(Icons.work_outline, size: context.w(12), color: const Color(0xff3B82F6)),
                    SizedBox(width: context.w(4)),
                    Text(
                      'Check-in: $checkin',
                      style: TextStyle(
                        color: const Color(0xff1E293B),
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.airline_seat_recline_extra, size: context.w(12), color: const Color(0xff8B5CF6)),
                    SizedBox(width: context.w(4)),
                    Text(
                      'Cabin: $cabin',
                      style: TextStyle(
                        color: const Color(0xff1E293B),
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: context.h(40),
            color: const Color(0xffE2E8F0),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Policy',
                  style: TextStyle(
                    color: const Color(0xff475569),
                    fontSize: context.fs(10),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Row(
                  children: [
                    Icon(
                      isFullyRefundable ? Icons.verified_outlined : Icons.info_outline,
                      size: context.w(12),
                      color: isFullyRefundable ? const Color(0xff22C55E) : const Color(0xffF59E0B),
                    ),
                    SizedBox(width: context.w(4)),
                    Text(
                      isFullyRefundable ? 'Free cancellation' : 'Non-refundable',
                      style: TextStyle(
                        color: const Color(0xff1E293B),
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.sync_alt, size: context.w(12), color: const Color(0xff3B82F6)),
                    SizedBox(width: context.w(4)),
                    // Was hardcoded to always claim "Free date change" — the
                    // FareRule bloc is already requested (see _loadFareRule)
                    // but its response was never read anywhere in this
                    // screen. Non-refundable/no-change fares exist, so a
                    // blanket "free" claim on a payment screen is a real bug.
                    Expanded(
                      child: BlocBuilder<AkFareRuleBloc, AkFareRuleState>(
                        bloc: _fareRuleBloc,
                        builder: (context, state) {
                          final loading = state is AkFareRuleLoading || state is AkFareRuleInitial;
                          final texts = state is AkFareRuleLoaded ? state.data.ruleTexts : const <String>[];
                          final changeFee = _extractFeeText(texts, const ['change', 'reissue']);
                          return Text(
                            loading ? 'Checking…' : (changeFee ?? 'As per fare rules'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xff1E293B),
                              fontSize: context.fs(11),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
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

  // ==================== BOOK BUTTON ====================
  Widget _bookButton(BuildContext context, AkFlightInfoEntity data, AkFlightInfoJourneyEntity journey, bool isFullyRefundable, bool fareChanged) {
    final bookingReady = _sessionId != null && _pricingTui != null && !_switchingFare && !_committing;
    final totalAmount = data.netAmount > 0 ? data.netAmount : widget.amount;

    return Container(
      padding: EdgeInsets.all(context.w(4)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bookingReady
              ? [const Color(0xff1E40AF), const Color(0xff3B82F6)]
              : [const Color(0xff94A3B8), const Color(0xff94A3B8)],
        ),
        borderRadius: BorderRadius.circular(context.r(16)),
        boxShadow: bookingReady ? [
          BoxShadow(
            color: const Color(0xff1E40AF).withValues(alpha: 0.3),
            blurRadius: context.w(16),
            offset: Offset(0, context.h(4)),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: bookingReady
              ? () => _handleBookNow(context, data, journey, isFullyRefundable, fareChanged)
              : null,
          borderRadius: BorderRadius.circular(context.r(16)),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: context.h(14), horizontal: context.w(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.fs(20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      bookingReady ? 'Book Now' : 'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (bookingReady) ...[
                      SizedBox(width: context.w(6)),
                      Icon(Icons.arrow_forward, color: Colors.white, size: context.w(18)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

  Widget _additionalLegsSummary(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(8)),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_horiz, size: context.w(16), color: const Color(0xff64748B)),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              '${widget.additionalLegs.length} more leg${widget.additionalLegs.length > 1 ? 's' : ''}',
              style: TextStyle(
                color: const Color(0xff475569),
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(2)),
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
            child: Text(
              'View',
              style: TextStyle(
                color: const Color(0xff3B82F6),
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
          'The price for this flight has changed to ₹${newAmount.toStringAsFixed(0)}. '
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

  void _bookNow(
      BuildContext context,
      AkFlightInfoEntity data,
      AkFlightInfoJourneyEntity journey,
      bool isFullyRefundable,
      ) {
    final totalPrice = '₹${data.netAmount.toStringAsFixed(0)}';
    Navigator.pop(context);

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
      );
    })
        .toList()
        : const <FlightRouteSegment>[];

    final segments = journey.segments;
    final firstFlight = segments.first.flight;
    final lastFlight = segments.last.flight;

    final route = FlightRouteSegment(
      from: firstFlight.departureCode,
      to: lastFlight.arrivalCode,
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
}
