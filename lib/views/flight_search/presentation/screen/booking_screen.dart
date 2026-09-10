import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/newUIWidgets/fare_breakup_sheet.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/traveller_info_card.dart';

import '../../../../common_widgets/airline_logo.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../fare_quote/domain/entities/fare_quote_entity.dart';
import '../../../login/presentation/screen/login.dart';
import '../../../AKGetSPricer/domain/entity/AKGetSPricer_entity.dart';
import '../../../AKTravelCheckList/domain/entity/AKTravelCheckList_entity.dart';
import '../../../AKTravelCheckList/presentation/bloc/AKTravelCheckList_bloc.dart';
import '../../../AKTravelCheckList/presentation/bloc/AKTravelCheckList_event.dart';
import '../../../AKTravelCheckList/presentation/bloc/AKTravelCheckList_state.dart';
import '../../../AKCreateItinerary/domain/entity/AKCreateItinerary_entity.dart';
import '../../../AKCreateItinerary/presentation/bloc/AKCreateItinerary_bloc.dart';
import '../../../AKCreateItinerary/presentation/bloc/AKCreateItinerary_event.dart';
import '../../../AKCreateItinerary/presentation/bloc/AKCreateItinerary_state.dart';
import '../../../flight_payment/presentation/screen/ak_trip_review_screen.dart';
import 'seat_addons_screen.dart';

class FlightRouteSegment {
  final String from;
  final String to;
  final String? fromCity;
  final String? toCity;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String airline;
  final String flightNo;
  final String? traceId;
  final String? resultIndex;
  final String price;

  final String? fareQuoteResultIndex;
  final bool? isRefundable;
  final bool? isHoldAllowed;
  final String? resultFareType;
  final FareQuoteData? fareQuoteData;

  final String? departureDate;
  final String? flightType;

  // Number of stops (0 = direct) and the IATA codes of the connecting
  // airports in between, derived from the journey's segment list. Null when
  // unknown (e.g. not yet populated by an older call site).
  final int? stops;
  final List<String>? viaAirports;

  // Akbar chain state, threaded from detail_popup.dart's
  // FlightInfo -> SmartPricer -> GetSPricer sequence.
  final String? searchTui; // original ExpressSearch/GetExpSearch tui
  final String? pricingTui; // GetSPricer's returned TUI (GetTravelCheckList needs this)
  final String? sessionId; // SmartPricer's session_id — used by every step from here on
  final double? amount; // the chosen result's fare amount (FareRule's trips[].amount)
  final AkGetSPricerEntity? akFareData; // GetSPricer's full response, for the fare breakdown

  FlightRouteSegment({
    required this.from,
    required this.to,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.airline,
    required this.flightNo,
    this.traceId,
    this.resultIndex,
    required this.price,
    this.fareQuoteResultIndex,
    this.isRefundable,
    this.isHoldAllowed,
    this.resultFareType,
    this.fareQuoteData,
    this.departureDate,    // NEW
    this.flightType,
    this.stops,
    this.viaAirports,
    this.searchTui,
    this.pricingTui,
    this.sessionId,
    this.amount,
    this.akFareData,
    this.fromCity,
    this.toCity,
  });

  factory FlightRouteSegment.fromFareQuoteEntity({
    required FlightRouteSegment original,
    required FareQuoteEntity entity,
  }) {
    final results = entity.response?.results;
    final fare = results?.fare;

    return FlightRouteSegment(
      from: original.from,
      to: original.to,
      fromCity: original.fromCity,
      toCity: original.toCity,
      departureTime: original.departureTime,
      arrivalTime: original.arrivalTime,
      duration: original.duration,
      airline: original.airline,
      flightNo: original.flightNo,
      traceId: original.traceId,
      resultIndex: original.resultIndex,
      price: original.price,
      fareQuoteResultIndex: results?.resultIndex,
      isRefundable: results?.isRefundable,
      isHoldAllowed: results?.isHoldAllowed,
      resultFareType: results?.resultFareType,
      fareQuoteData: fare != null
          ? FareQuoteData(
              currency: fare.currency ?? 'USD',
              baseFare: fare.baseFare ?? 0.0,
              tax: fare.tax ?? 0.0,
              offeredFare: fare.offeredFare ?? 0.0,
              publishedFare: fare.publishedFare ?? 0.0,
              serviceFee: 0.0,
              isLcc: results?.isLcc ?? false,
              rawItinerary: results?.raw ?? const {},
            )
          : null,
      departureDate: original.departureDate,
      flightType: original.flightType,
      stops: original.stops,
      viaAirports: original.viaAirports,
    );
  }

  /// Synthesizes a [FareQuoteData]-shaped view over GetSPricer's response so
  /// the existing fare-breakdown UI (built against the old TBO FareQuote
  /// shape) can render Akbar's data with no other changes — there's no
  /// separate fare fetch here, GetSPricer already ran in detail_popup.dart.
  factory FlightRouteSegment.fromAkFareData({
    required FlightRouteSegment original,
    required AkGetSPricerEntity data,
  }) {
    final segments = data.trips.isNotEmpty && data.trips.first.journey.isNotEmpty
        ? data.trips.first.journey.first.segments
        : const <AkGetSPricerSegmentEntity>[];
    final baseFare = segments.fold<double>(0, (s, seg) => s + seg.fare.totalBaseFare);
    final taxesAndFees = segments.fold<double>(
      0,
      (s, seg) => s + seg.fare.totalTax + seg.fare.totalServiceTax + seg.fare.totalTransactionFee,
    );

    return FlightRouteSegment(
      from: original.from,
      to: original.to,
      fromCity: original.fromCity,
      toCity: original.toCity,
      departureTime: original.departureTime,
      arrivalTime: original.arrivalTime,
      duration: original.duration,
      airline: original.airline,
      flightNo: original.flightNo,
      traceId: original.traceId,
      resultIndex: original.resultIndex,
      price: original.price,
      fareQuoteData: FareQuoteData(
        currency: 'INR',
        baseFare: baseFare,
        tax: taxesAndFees,
        offeredFare: data.netAmount,
        publishedFare: data.grossAmount,
        serviceFee: 0.0,
      ),
      departureDate: original.departureDate,
      flightType: original.flightType,
      stops: original.stops,
      viaAirports: original.viaAirports,
      searchTui: original.searchTui,
      pricingTui: original.pricingTui,
      sessionId: original.sessionId,
      amount: original.amount,
      akFareData: data,
    );
  }
}

class FareQuoteData {
  final String currency;
  final double baseFare;
  final double tax;
  final double offeredFare;
  final double publishedFare;
  final double serviceFee;

  /// True when the airline is an LCC (SpiceJet, IndiGo, …). LCC itineraries
  /// skip the Book step and ticket directly. Comes from the FareQuote result.
  final bool isLcc;

  /// The complete TBO FareQuote result object, sent verbatim as the Book/Ticket
  /// `Itinerary`. Empty when no fare quote was captured.
  final Map<String, dynamic> rawItinerary;

  double get total => offeredFare + serviceFee;

  /// True when the TBO FareQuote result flags passport as required for all pax.
  /// This can be true even on domestic routes (e.g. Air India domestic, some
  /// GDS fares). When true the booking form must collect passport details.
  ///
  /// Uses a case-insensitive key scan so it catches TBO's inconsistent field
  /// casing (IsPassportRequired, IsPassportRequiredForAllPax, etc.) and also
  /// treats integer 1 / string "true" as truthy.
  bool get isPassportRequired {
    for (final entry in rawItinerary.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('passport') && key.contains('required')) {
        final v = entry.value;
        if (v == true || v == 1 || v?.toString().toLowerCase() == 'true') {
          return true;
        }
      }
    }
    return false;
  }

  FareQuoteData({
    required this.currency,
    required this.baseFare,
    required this.tax,
    required this.offeredFare,
    required this.publishedFare,
    required this.serviceFee,
    this.isLcc = false,
    this.rawItinerary = const {},
  });
}

/// "Direct Flight" when there are no stops, otherwise the stop count and
/// (when known) the connecting airport(s), e.g. "1 Stop via BOM".
String _stopsLabel(FlightRouteSegment route) {
  final stops = route.stops;
  if (stops == null || stops <= 0) return 'Direct Flight';
  final via = route.viaAirports != null && route.viaAirports!.isNotEmpty
      ? ' via ${route.viaAirports!.join(', ')}'
      : '';
  return '$stops Stop${stops > 1 ? 's' : ''}$via';
}

class FlightBookingScreen extends StatefulWidget {
  final List<FlightRouteSegment> routes;
  final String totalPrice;
  final bool isLoggedIn;
  final String? resultIndex;
  final String? traceId;
  final String price;

  /// Number of travellers — used to cap seat selection on the SSR screen.
  final int travellerCount;

  /// The SearchCard's passenger split, so the traveller form renders one
  /// Adult / Child / Infant block per selected passenger. All zero falls back
  /// to [travellerCount] adults.
  final int adultCount;
  final int childCount;
  final int infantCount;

  /// Combined cost of any seats/baggage/meals picked on [SeatAddonsScreen]
  /// (always in INR, per that screen's SelectSeats/SelectSSR amounts).
  /// Those selections are saved server-side against the session, so
  /// CreateItinerary's netAmount already includes them — this is purely so
  /// the Fare Breakdown card below reflects the same total instead of
  /// showing the pre-add-ons GetSPricer fare. Defaults to 0 for call sites
  /// that never went through the add-ons screen, which keeps the existing
  /// breakdown byte-identical when there are no add-ons.
  final double addOnsTotal;

  const FlightBookingScreen({
    super.key,
    required this.routes,
    required this.totalPrice,
    required this.isLoggedIn,
    this.resultIndex,
    this.traceId,
    required this.price,
    this.travellerCount = 1,
    this.adultCount = 0,
    this.childCount = 0,
    this.infantCount = 0,
    this.addOnsTotal = 0.0,
  });

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  late final AkTravelCheckListBloc _checkListBloc;
  late final AkCreateItineraryBloc _createItineraryBloc;

  final _formKey = GlobalKey<TravellerFormState>();

  // GetSPricer already fetched the live fare upstream in detail_popup.dart —
  // this is synthesized once from route.akFareData, not fetched again here.
  FlightRouteSegment? _updatedRouteWithFareQuote;
  bool _isLoggedIn() => di.sl<PreferencesManager>().isLoggedIn();

  bool _promoCodeApplied = false;
  String _appliedPromoCode = '';
  double _promoDiscountAmount = 0.0;
  final TextEditingController _promoCodeController = TextEditingController();

  // Guards CreateItinerary's itinerary_changed retry to exactly one attempt.
  bool _itineraryRetried = false;
  bool _submittingItinerary = false;

  /// Seats/baggage/meals total. Seeded from [widget.addOnsTotal] and updated
  /// when [SeatAddonsScreen] returns its picks, so the fare breakdown and the
  /// bottom bar stay in step with what the user chose.
  late double _addOnsTotal = widget.addOnsTotal;

  // Section anchors for the Figma chip row (Traveller details / Offers /
  // Insurance / Booking policies).
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _travellerSectionKey = GlobalKey();
  final GlobalKey _offersSectionKey = GlobalKey();
  final GlobalKey _insuranceSectionKey = GlobalKey();
  final GlobalKey _policiesSectionKey = GlobalKey();
  int _activeSection = 0;

  /// Figma shows two offer cards plus a "View more" toggle.
  bool _showAllOffers = false;

  /// Passenger split for the traveller form. Prefers what the SearchCard
  /// selected, falls back to GetSPricer's echo for this fare, and finally to
  /// "everyone is an adult".
  ({int adults, int children, int infants}) get _paxSplit {
    if (widget.adultCount > 0 || widget.childCount > 0 || widget.infantCount > 0) {
      return (
        adults: widget.adultCount,
        children: widget.childCount,
        infants: widget.infantCount,
      );
    }
    final pricer = (_updatedRouteWithFareQuote ?? widget.routes.first).akFareData;
    if (pricer != null &&
        (pricer.adultCount > 0 || pricer.childCount > 0 || pricer.infantCount > 0)) {
      return (
        adults: pricer.adultCount,
        children: pricer.childCount,
        infants: pricer.infantCount,
      );
    }
    return (adults: widget.travellerCount < 1 ? 1 : widget.travellerCount, children: 0, infants: 0);
  }

  int get _totalPax {
    final s = _paxSplit;
    final total = s.adults + s.children + s.infants;
    return total < 1 ? 1 : total;
  }

  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _border = Color(0xFFE2E7F0);

  // ---- Figma tokens (reusing AppColors where they already match) ----
  static const _pri = AppColors.AppBlue; // Pri            #00A1E4
  static const _sec = AppColors.OrangeColor; // Sec        #FF6600
  static const _muted = AppColors.subhead; // text         #757575
  static const _stroke = Color(0xFFCCCCCC); // Strok       #CCCCCC
  static const _hairline = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();

    _checkListBloc = di.sl<AkTravelCheckListBloc>();
    _createItineraryBloc = di.sl<AkCreateItineraryBloc>();

    final route = widget.routes.isNotEmpty ? widget.routes.first : null;
    if (route?.akFareData != null) {
      _updatedRouteWithFareQuote = FlightRouteSegment.fromAkFareData(
        original: route!,
        data: route.akFareData!,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTravelCheckList();
      final bloc = context.read<GeneralSettingsBloc>();
      if (bloc.state is! PromoCodesLoaded) {
        bloc.add(const LoadPromoCodes());
      }
    });
  }

  void _fetchTravelCheckList() {
    final route = widget.routes.isNotEmpty ? widget.routes.first : null;
    final pricingTui = route?.pricingTui;
    if (pricingTui == null || pricingTui.isEmpty) {
      print('FlightBookingScreen: pricingTui not available, skipping GetTravelCheckList');
      return;
    }
    _checkListBloc.add(LoadAkTravelCheckListEvent(
      AkTravelCheckListRequestEntity(tui: pricingTui),
    ));
  }

  String _getPreferredCurrencySymbol() {
    final prefs = di.sl<PreferencesManager>();
    final preferredCurrency = prefs.getPreferredCurrency() ?? 'INR';
    return CurrencyConverter.getSymbol(preferredCurrency);
  }

  void _removePromoCode() {
    setState(() {
      _promoCodeApplied = false;
      _appliedPromoCode = '';
      _promoDiscountAmount = 0.0;
      _promoCodeController.clear();
    });
  }

  // Add this method to _FlightBookingScreenState
  void _showCelebrationDialog(double discountAmount, String promoCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lottie Animation - make sure you have the asset
                Container(
                  height: 200,
                  width: double.infinity,
                  child: Lottie.asset(
                    'assets/animation/celebrate.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                // Success Message
                Text(
                  '🎉 Promo Applied!',
                  style: TextStyle(
                    fontSize: context.titleLarge,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You saved ${_getPreferredCurrencySymbol()}${discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: $promoCode',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Great!',
                      style: TextStyle(
                        fontSize: context.bodyLarge,
                        fontWeight: FontWeight.w700,
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
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a promo code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final bloc = context.read<GeneralSettingsBloc>();
    List<PromoCodeEntity> promoCodes = [];

    if (bloc.state is PromoCodesLoaded) {
      promoCodes = (bloc.state as PromoCodesLoaded).promoCodes;
    }

    final matchedPromo = promoCodes.firstWhere(
          (p) => p.code.toUpperCase() == code,
      orElse: () => const PromoCodeEntity(
          code: '',
          category: '',
          discountType: '',
          discountValue: '0',
          description: ''
      ),
    );

    if (matchedPromo.code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid promo code. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Calculate discount
    double discount = 0;
    final discountValue = double.tryParse(matchedPromo.discountValue) ?? 0;

    final route = _updatedRouteWithFareQuote ?? widget.routes.first;
    final fare = route.fareQuoteData;
    String originalCurrency = fare?.currency ?? 'INR';
    // Add-ons are always quoted in INR (see [FlightBookingScreen.addOnsTotal]);
    // convert into whatever currency the fare itself is in before folding it
    // into the base the promo discount is computed against.
    final addOnsInFareCurrency = originalCurrency.toUpperCase() == 'INR'
        ? _addOnsTotal
        : CurrencyConverter.convert(
            amount: _addOnsTotal,
            fromCurrency: 'INR',
            toCurrency: originalCurrency,
          );
    double baseTotal = (fare?.total ?? double.tryParse(widget.totalPrice) ?? 0) + addOnsInFareCurrency;

    if (matchedPromo.discountType == 'percent') {
      double discountOriginal = (baseTotal * discountValue) / 100;
      try {
        final prefs = di.sl<PreferencesManager>();
        final preferredCurrency = prefs.getPreferredCurrency() ?? 'INR';
        if (originalCurrency.toUpperCase() != preferredCurrency.toUpperCase()) {
          discount = CurrencyConverter.convert(
            amount: discountOriginal,
            fromCurrency: originalCurrency,
            toCurrency: preferredCurrency,
          );
        } else {
          discount = discountOriginal;
        }
      } catch (e) {
        discount = discountOriginal;
      }
    } else {
      try {
        final prefs = di.sl<PreferencesManager>();
        final preferredCurrency = prefs.getPreferredCurrency() ?? 'INR';
        if (originalCurrency.toUpperCase() != preferredCurrency.toUpperCase()) {
          discount = CurrencyConverter.convert(
            amount: discountValue,
            fromCurrency: originalCurrency,
            toCurrency: preferredCurrency,
          );
        } else {
          discount = discountValue;
        }
      } catch (e) {
        discount = discountValue;
      }
    }

    setState(() {
      _promoCodeApplied = true;
      _appliedPromoCode = matchedPromo.code;
      _promoDiscountAmount = discount;
    });

    // Show celebration dialog instead of SnackBar
    _showCelebrationDialog(discount, matchedPromo.code);
  }

  /// [widget.addOnsTotal] (seats/baggage/meals picked on the add-ons screen,
  /// always INR) converted into the caller's preferred display currency.
  double _addOnsInDisplayCurrency(String targetCurrency) {
    if (_addOnsTotal <= 0) return 0;
    return targetCurrency.toUpperCase() == 'INR'
        ? _addOnsTotal
        : CurrencyConverter.convert(
            amount: _addOnsTotal,
            fromCurrency: 'INR',
            toCurrency: targetCurrency,
          );
  }

  String _getFinalTotalDisplay(FareQuoteData fare) {
    final totalInOriginal = fare.total;
    final originalCurrency = fare.currency;

    try {
      final prefs = di.sl<PreferencesManager>();
      final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';

      double convertedTotal = totalInOriginal;
      if (originalCurrency.toUpperCase() != targetCurrency.toUpperCase()) {
        convertedTotal = CurrencyConverter.convert(
          amount: totalInOriginal,
          fromCurrency: originalCurrency,
          toCurrency: targetCurrency,
        );
      }

      // Deliberately excludes the Trip Secure premium: the flight total shown
      // here has to match what the payment screen charges (CreateItinerary's
      // netAmount for this session), and the insurance premium is not part of
      // that charge — see [_insurancePremiumInDisplayCurrency]. Seat/baggage/
      // meal add-ons ARE part of that netAmount (SelectSeats/SelectSSR save
      // them to the session before CreateItinerary runs), so they're added
      // in here.
      final finalTotal = convertedTotal + _addOnsInDisplayCurrency(targetCurrency) - _promoDiscountAmount;
      return CurrencyConverter.format(finalTotal > 0 ? finalTotal : 0, targetCurrency);
    } catch (e) {
      return _convertFareAmount(totalInOriginal, originalCurrency);
    }
  }

  bool get _isInternationalRoute {
    if (widget.routes.isEmpty) return false;
    final route = widget.routes.first;
    final fromCode = _extractAirportCode(route.from);
    final toCode = _extractAirportCode(route.to);
    return !_indianAirportCodes.contains(fromCode) ||
        !_indianAirportCodes.contains(toCode);
  }

  /// Passport-required-ness is driven by GetTravelCheckList when it's
  /// available; when the checklist is unavailable (called too early,
  /// still loading, or failed) this falls back to the route-based
  /// domestic/international heuristic as the conservative default.
  bool _isPassportRequired(AkTravelCheckListState checklistState) {
    if (checklistState is AkTravelCheckListLoaded && !checklistState.data.unavailable) {
      final list = checklistState.data.travellerCheckList;
      if (list.isNotEmpty) {
        return list.any((e) => e.passportNo);
      }
    }
    return _isInternationalRoute;
  }

  String _extractAirportCode(String value) {
    final match = RegExp(r'\(([A-Z]{3})\)').firstMatch(value.toUpperCase());
    if (match != null) return match.group(1)!;

    final compact = value.trim().toUpperCase();
    if (compact.length == 3) return compact;
    return compact.split(RegExp(r'[\s,/-]+')).first;
  }

  String _convertFareAmount(double amount, String currency) {
    try {
      final prefs = di.sl<PreferencesManager>();
      final targetCurrency = prefs.getPreferredCurrency() ?? 'INR';
      final sourceCurrency = currency.isEmpty ? 'INR' : currency;

      final converted =
          sourceCurrency.toUpperCase() == targetCurrency.toUpperCase()
          ? amount
          : CurrencyConverter.convert(
              amount: amount,
              fromCurrency: sourceCurrency,
              toCurrency: targetCurrency,
            );

      return CurrencyConverter.format(converted, targetCurrency);
    } catch (e) {
      return CurrencyConverter.format(amount, currency);
    }
  }

  static const Set<String> _indianAirportCodes = {
    'AMD',
    'ATQ',
    'BBI',
    'BDQ',
    'BHO',
    'BLR',
    'BOM',
    'CCU',
    'CJB',
    'COK',
    'DED',
    'DEL',
    'GAU',
    'GOI',
    'GOX',
    'HYD',
    'IDR',
    'IXC',
    'IXR',
    'JAI',
    'LKO',
    'MAA',
    'NAG',
    'PAT',
    'PNQ',
    'RPR',
    'SXR',
    'TRV',
    'UDR',
    'VNS',
    'VTZ',
  };

  @override
  void dispose() {
    _checkListBloc.close();
    _createItineraryBloc.close();
    _promoCodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildPromoInputRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _promoCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'ENTER COUPON CODE',
              hintStyle: TextStyle(
                  fontSize: context.bodySmall, color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
                borderSide: const BorderSide(color: _blue, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.w(12), vertical: context.h(12)),
              isDense: true,
            ),
          ),
        ),
        SizedBox(width: context.gapSmall),
        SizedBox(
          height: context.h(46),
          child: ElevatedButton(
            onPressed: _applyPromoCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.AppBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8))),
            ),
            child: Text(
              'APPLY',
              style: TextStyle(
                  fontSize: context.bodyMedium, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AkTravelCheckListBloc>.value(value: _checkListBloc),
        BlocProvider<AkCreateItineraryBloc>.value(value: _createItineraryBloc),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: context.h(16)),
              _buildSectionChips(context),
              SizedBox(height: context.h(24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isLoggedIn()) ...[
                      _buildLoginCard(context),
                      SizedBox(height: context.h(24)),
                    ],
                    _buildTravellerSection(context),
                    SizedBox(height: context.h(24)),
                    _buildOffersSection(context),
                    if (_isInternationalRoute) ...[
                      SizedBox(height: context.h(24)),
                      _buildInsuranceSection(context),
                    ],
                    SizedBox(height: context.h(24)),
                    _buildBookingPoliciesSection(context),
                    SizedBox(height: context.h(24)),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header — Figma nodes 447:1181 (domestic) / 450:2110 (international)
  // ---------------------------------------------------------------------------

  /// First / last flight of a leg, straight off GetSPricer's response — this
  /// is where aircraft type, cabin class and terminals live.
  AkGetSPricerFlightEntity? _flightOf(FlightRouteSegment route, {required bool last}) {
    final trips = route.akFareData?.trips;
    if (trips == null || trips.isEmpty) return null;
    final journeys = trips.first.journey;
    if (journeys.isEmpty) return null;
    final segments = journeys.first.segments;
    if (segments.isEmpty) return null;
    return last ? segments.last.flight : segments.first.flight;
  }

  AkGetSPricerBaggageEntity? _includedBaggage(FlightRouteSegment route) {
    final map = route.akFareData?.includedBaggage;
    if (map == null || map.isEmpty) return null;
    final perPax = map.values.first;
    if (perPax.isEmpty) return null;
    return perPax['ADT'] ?? perPax.values.first;
  }

  /// "25 Aug, Tue" from GetSPricer's raw segment timestamp, falling back to
  /// the already-formatted date the route carries.
  String _segmentDate(String raw, String fallback) {
    final value = raw.trim();
    if (value.isEmpty) return fallback;
    try {
      return DateFormat('dd MMM, EEE').format(DateTime.parse(value.replaceFirst(' ', 'T')));
    } catch (_) {
      return fallback;
    }
  }



  String _headerTitle(FlightRouteSegment route) {
    // City names come from GetSPricer's airport names (see detail_popup's
    // `_shortCityName`); the IATA code is only a fallback when the API didn't
    // give one.
    final from = (route.fromCity ?? '').trim();
    final to = (route.toCity ?? '').trim();
    return '${from.isNotEmpty ? from : route.from} to ${to.isNotEmpty ? to : route.to}';
  }

  Widget _buildHeader(BuildContext context) {
    final route = _updatedRouteWithFareQuote ?? widget.routes.first;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: context.h(24)),
      decoration: BoxDecoration(
        // Figma: linear-gradient(-76.78deg, #FFFFFF 25%, #80DAFF 182%)
        gradient: const LinearGradient(
          begin: Alignment(-1, 1),
          end: Alignment(1, -1),
          colors: [Color(0xFF80DAFF), Color(0xFFFFFFFF)],
          stops: [0.0, 0.85],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.r(24))),
      ),
      clipBehavior: Clip.hardEdge,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: context.h(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Image.asset(
                      'assets/NewIcons/arrowBack.png',
                      width: context.w(18),
                      height: context.h(18),
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Text(
                      _headerTitle(route),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: context.fs(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  Icon(Icons.share, size: context.w(18), color: Colors.black),
                ],
              ),
            ),
            SizedBox(height: context.h(24)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: Column(
                children: [
                  for (var i = 0; i < widget.routes.length; i++) ...[
                    if (i > 0) SizedBox(height: context.h(12)),
                    _buildFlightCard(
                      context,
                      i == 0 ? route : widget.routes[i],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The white flight card inside the header (Figma nodes 447:1220 / 450:2129).
  Widget _buildFlightCard(BuildContext context, FlightRouteSegment route) {
    final first = _flightOf(route, last: false);
    final last = _flightOf(route, last: true);

    final flightNo = route.flightNo.replaceAll('•', '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final aircraft = (first?.aircraft.trim().isNotEmpty ?? false)
        ? first!.aircraft.trim()
        : (first?.equipmentType.trim() ?? '');
    final cabin = (first?.cabin ?? '').trim();

    String endpoint(String code, String terminal) =>
        terminal.trim().isEmpty ? code : '$code, Terminal ${terminal.trim()}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- airline row ----
          Container(
            padding: EdgeInsets.only(top: context.h(16), bottom: context.h(17)),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _hairline)),
            ),
            child: Row(
              children: [
                AirlineLogo(
                  code: route.flightNo.contains('•')
                      ? route.flightNo.split('•').first.trim()
                      : '',
                  name: route.airline,
                  size: context.w(32),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              route.airline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.fs(14),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: context.w(4)),
                          Text(
                            flightNo,
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w500,
                              color: _muted,
                              height: 1.43,
                            ),
                          ),
                        ],
                      ),
                      if (aircraft.isNotEmpty)
                        Text(
                          aircraft,
                          style: TextStyle(
                            fontSize: context.fs(12),
                            color: _muted,
                            height: 1.33,
                          ),
                        ),
                    ],
                  ),
                ),
                if (cabin.isNotEmpty) ...[
                  SizedBox(width: context.w(8)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(4)),
                    decoration: BoxDecoration(
                      color: _pri.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(context.r(999)),
                    ),
                    child: Text(
                      _getFullCabinName(cabin),
                      // cabin.toUpperCase(),
                      style: TextStyle(
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w700,
                        color: _pri,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: context.h(24)),
          // ---- times / duration / route ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEndpointColumn(
                context,
                time: route.departureTime,
                date: _segmentDate(first?.departureTime ?? '', route.departureDate ?? ''),
                place: endpoint(route.from, first?.departureTerminal ?? ''),
                alignEnd: false,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule_rounded, size: context.w(11.6), color: _muted),
                          SizedBox(width: context.w(4)),
                          Flexible(
                            child: Text(
                              route.duration,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.fs(10),
                                fontWeight: FontWeight.w700,
                                color: _muted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.h(14)),
                      SizedBox(
                        height: context.h(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(height: 1, color: _pri),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _dot(context),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _dot(context),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.h(14)),
                      Text(
                        _stopsLabel(route).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w700,
                          color: _muted,
                          letterSpacing: 1,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildEndpointColumn(
                context,
                time: route.arrivalTime,
                date: _segmentDate(last?.arrivalTime ?? '', route.departureDate ?? ''),
                place: endpoint(route.to, last?.arrivalTerminal ?? ''),
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFullCabinName(String code) {
    switch (code.toUpperCase()) {
      case 'E':
        return 'ECONOMY';
      case 'PE':
        return 'PREMIUM ECONOMY';
      case 'B':
        return 'BUSINESS';
      case 'F':
        return 'FIRST';
      default:
        return code.toUpperCase();
    }
  }

  Widget _dot(BuildContext context) => Container(
        width: context.w(8),
        height: context.w(8),
        decoration: const BoxDecoration(color: _pri, shape: BoxShape.circle),
      );

  Widget _buildEndpointColumn(
    BuildContext context, {
    required String time,
    required String date,
    required String place,
    required bool alignEnd,
  }) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: context.fs(18),
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: context.h(2)),
        if (date.isNotEmpty)
          Text(
            date,
            style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w500, color: _muted),
          ),
        SizedBox(height: context.h(2)),
        Text(
          place,
          style: TextStyle(fontSize: context.fs(10), color: _muted),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section chips — Figma nodes 447:1254 / 450:2161
  // ---------------------------------------------------------------------------

  List<({String label, GlobalKey key})> get _sections => [
        (label: 'Traveller details', key: _travellerSectionKey),
        (label: 'Offers', key: _offersSectionKey),
        if (_isInternationalRoute) (label: 'Insurance', key: _insuranceSectionKey),
        (label: 'Booking policies', key: _policiesSectionKey),
      ];

  void _scrollToSection(int index) {
    setState(() => _activeSection = index);
    final ctx = _sections[index].key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  Widget _buildSectionChips(BuildContext context) {
    final sections = _sections;
    return SizedBox(
      height: context.h(28),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.w(16)),
        itemCount: sections.length,
        separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
        itemBuilder: (context, i) {
          final active = i == _activeSection;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _scrollToSection(i),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(4)),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF0066CB).withValues(alpha: 0.04) : Colors.white,
                borderRadius: BorderRadius.circular(context.r(6)),
                border: Border.all(color: active ? _pri : _stroke, width: 0.5),
              ),
              child: Text(
                sections[i].label,
                style: TextStyle(
                  fontSize: context.fs(12),
                  fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                  color: active ? _pri : _muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text, {String? trailing}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: context.fs(16),
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.45,
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: _muted,
                height: 1.33,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Traveller Details — Figma nodes 450:2387 / 453:2925
  // ---------------------------------------------------------------------------

  Widget _buildTravellerSection(BuildContext context) {
    return Column(
      key: _travellerSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Traveller Details'),
            // trailing: '0/${widget.travellerCount} Added'),
        SizedBox(height: context.h(16)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.w(16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: _stroke, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: BlocBuilder<AkTravelCheckListBloc, AkTravelCheckListState>(
            builder: (context, checklistState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (checklistState is AkTravelCheckListLoaded &&
                      checklistState.data.unavailable)
                    _buildCheckListUnavailableBanner(context),
                  // `validateForm()` / `getAllTravellersData()` keep the same
                  // contract `_validateAndProceed` depends on. The checklist
                  // is handed down so the Add-Traveller sheet asks only for
                  // the fields this airline actually requires.
                  TravellerInformationSection(
                    key: _formKey,
                    isInternational: _isPassportRequired(checklistState),
                    travellerCount: _totalPax,
                    adultCount: _paxSplit.adults,
                    childCount: _paxSplit.children,
                    infantCount: _paxSplit.infants,
                    checkList: checklistState is AkTravelCheckListLoaded
                        ? checklistState.data
                        : null,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Offers — Figma nodes 453:2804 / 453:2861
  // ---------------------------------------------------------------------------

  Widget _buildOffersSection(BuildContext context) {
    return BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
      builder: (context, state) {
        // A promo tagged for both 'flight_booking' and 'payment' (or simply
        // duplicated server-side) otherwise renders as two identical cards —
        // one showing "Apply", the other "Remove" once applied. Keep only the
        // first occurrence of each code so every offer shows exactly once.
        final seenCodes = <String>{};
        final all = state is PromoCodesLoaded
            ? state.promoCodes
                .where((p) => p.category == 'flight_booking' || p.category == 'payment')
                .where((p) {
                  final code = p.code.trim().toUpperCase();
                  return code.isNotEmpty && seenCodes.add(code);
                })
                .toList()
            : <PromoCodeEntity>[];
        final visible = _showAllOffers ? all : all.take(2).toList();

        return Column(
          key: _offersSectionKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Offers'),
            SizedBox(height: context.h(16)),
            if (all.isEmpty)
              _buildPromoInputRow(context)
            else ...[
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) SizedBox(height: context.h(12)),
                _buildOfferCard(context, visible[i]),
              ],
              if (all.length > 2) ...[
                SizedBox(height: context.h(8)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showAllOffers = !_showAllOffers),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _showAllOffers ? 'View less' : 'View more',
                        style: TextStyle(
                          fontSize: context.fs(10),
                          fontWeight: FontWeight.w600,
                          color: _pri,
                        ),
                      ),
                      SizedBox(width: context.w(4)),
                      Icon(
                        _showAllOffers
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: context.w(14),
                        color: _pri,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  /// One promo card (Figma node 453:2807). Applied cards get the cyan border
  /// and a red "Remove"; the rest show a cyan "Apply".
  Widget _buildOfferCard(BuildContext context, PromoCodeEntity promo) {
    final isApplied = _promoCodeApplied &&
        _appliedPromoCode.toUpperCase() == promo.code.toUpperCase();

    final offLabel = promo.discountType == 'percent'
        ? '${double.tryParse(promo.discountValue)?.toStringAsFixed(0) ?? promo.discountValue}% off'
        : '${_getPreferredCurrencySymbol()}${promo.discountValue} off';

    final body = isApplied
        ? 'Congratulations! Promo Discount of ${_getPreferredCurrencySymbol()}${_promoDiscountAmount.toStringAsFixed(0)} applied successfully to your booking.'
        : (promo.description.isNotEmpty
            ? promo.description
            : 'Apply this code to get $offLabel on your booking.');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: isApplied ? _pri : _stroke,
          width: isApplied ? 1 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApplied ? Icons.check_circle : Icons.local_offer_outlined,
                size: context.w(21),
                color: isApplied ? const Color(0xFF16A34A) : _pri,
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Text(
                  promo.code.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              SizedBox(width: context.w(8)),
              Text(
                offLabel,
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w600,
                  color: _pri,
                  height: 1.56,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(11)),
          Text(
            body,
            style: TextStyle(fontSize: context.fs(12), color: _muted),
          ),
          SizedBox(height: context.h(11)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: context.h(12.5)),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _stroke, width: 0.5)),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (isApplied) {
                    _removePromoCode();
                  } else {
                    _promoCodeController.text = promo.code;
                    _applyPromoCode();
                  }
                },
                child: Text(
                  isApplied ? 'Remove' : 'Apply',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w800,
                    color: isApplied ? const Color(0xFFFF383C) : _pri,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Insurance (international only) — Figma node 453:2890
  // ---------------------------------------------------------------------------

  Widget _buildInsuranceSection(BuildContext context) {
    final benefits = <({IconData icon, Color bg, Color fg, String label, String value})>[
      (
        icon: Icons.local_hospital_rounded,
        bg: const Color(0xFFFEF2F2),
        fg: const Color(0xFFEF4444),
        label: 'Medical Expenses',
        value: r'$250,000'
      ),
      (
        icon: Icons.event_busy_rounded,
        bg: const Color(0xFFFFFBEB),
        fg: const Color(0xFFF59E0B),
        label: 'Trip Cancellation',
        value: r'$2,500'
      ),
      (
        icon: Icons.luggage_rounded,
        bg: const Color(0xFFEFF6FF),
        fg: const Color(0xFF3B82F6),
        label: 'Delayed Baggage',
        value: r'$500'
      ),
    ];

    return Column(
      key: _insuranceSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Insurance'),
        SizedBox(height: context.h(16)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(24)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.white, Color(0xFF80DAFF)],
              stops: [0.1, 1.0],
            ),
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety_rounded, size: context.w(56), color: _pri),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'International ',
                          style: TextStyle(color: const Color(0xFF0B9D9D), fontSize: context.fs(18)),
                        ),
                        TextSpan(
                          text: 'Travel + Medical Insurance',
                          style: TextStyle(color: Colors.black, fontSize: context.fs(18)),
                        ),
                      ]),
                      style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.45),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(24)),
              SizedBox(
                height: context.h(130),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: benefits.length,
                  separatorBuilder: (_, __) => SizedBox(width: context.w(12)),
                  itemBuilder: (context, i) {
                    final b = benefits[i];
                    return Container(
                      width: context.w(160),
                      padding: EdgeInsets.all(context.w(16)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.r(16)),
                        border: Border.all(color: _hairline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: context.w(40),
                            height: context.w(40),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: b.bg,
                              borderRadius: BorderRadius.circular(context.r(12)),
                            ),
                            child: Icon(b.icon, size: context.w(20), color: b.fg),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                b.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.fs(12),
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                b.value,
                                style: TextStyle(
                                  fontSize: context.fs(18),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: context.h(24)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _scrollToSection(_sections.length - 1),
                child: Container(
                  width: double.infinity,
                  height: context.h(44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.r(8)),
                    border: Border.all(color: _sec),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All Benefits',
                        style: TextStyle(
                          fontSize: context.fs(14),
                          fontWeight: FontWeight.w600,
                          color: _sec,
                        ),
                      ),
                      SizedBox(width: context.w(4)),
                      Icon(Icons.arrow_forward_rounded, size: context.w(20), color: _sec),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Booking Policies — Figma nodes 447:1326 / 453:2836
  // ---------------------------------------------------------------------------

  Widget _buildBookingPoliciesSection(BuildContext context) {
    final route = _updatedRouteWithFareQuote ?? widget.routes.first;
    final baggage = _includedBaggage(route);
    final refundable = route.isRefundable == true;

    Widget bagRow(IconData icon, String label, String value) => Row(
          children: [
            Icon(icon, size: context.w(13), color: AppColors.black),
            SizedBox(width: context.w(8)),
            Text(label, style: TextStyle(fontSize: context.fs(10), color: _muted)),
            SizedBox(width: context.w(8)),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: value, style: const TextStyle(color: Colors.black)),
                TextSpan(text: ' /adult', style: TextStyle(color: _muted)),
              ]),
              style: TextStyle(fontSize: context.fs(10)),
            ),
          ],
        );

    Widget bullet(String bold, String rest) => Padding(
          padding: EdgeInsets.only(top: context.h(6)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: context.h(4)),
                child: Container(
                  width: context.w(2),
                  height: context.w(2),
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                ),
              ),
              SizedBox(width: context.w(6)),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: bold,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    TextSpan(text: rest, style: TextStyle(color: _muted)),
                  ]),
                  style: TextStyle(fontSize: context.fs(8)),
                ),
              ),
            ],
          ),
        );

    return Column(
      key: _policiesSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Booking Policies'),
        SizedBox(height: context.h(16)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: _stroke, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (baggage != null) ...[
                if (baggage.cabin.trim().isNotEmpty)
                  bagRow(Icons.work_outline_rounded, 'Cabin Bag:', baggage.cabin.trim()),
                if (baggage.cabin.trim().isNotEmpty && baggage.checkin.trim().isNotEmpty)
                  SizedBox(height: context.h(8)),
                if (baggage.checkin.trim().isNotEmpty)
                  bagRow(Icons.luggage_outlined, 'Check-in:', baggage.checkin.trim()),
                SizedBox(height: context.h(12)),
              ],
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: context.h(12)),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: baggage != null ? _stroke : Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancellation refund & date change',
                      style: TextStyle(
                        fontSize: context.fs(10),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    bullet(
                      'Cancellation: ',
                      refundable
                          ? 'This fare is refundable. Airline cancellation charges apply as per the fare rules.'
                          : 'This fare is non-refundable. Airline cancellation charges apply as per the fare rules.',
                    ),
                    bullet(
                      'Date change: ',
                      'Airline date-change fee plus any fare difference applies, as per the fare rules.',
                    ),
                  ],
                ),
              ),
              // SizedBox(height: context.h(4)),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: GestureDetector(
              //     behavior: HitTestBehavior.opaque,
              //     onTap: () {
              //       final searchTui = route.searchTui;
              //       final resultIndex = widget.resultIndex ?? route.resultIndex;
              //       if (searchTui == null ||
              //           searchTui.isEmpty ||
              //           resultIndex == null ||
              //           resultIndex.isEmpty) {
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           const SnackBar(content: Text('Fare rules are not available for this fare.')),
              //         );
              //         return;
              //       }
              //       AkFareRulePopup.show(
              //         context,
              //         searchTui: searchTui,
              //         resultIndex: resultIndex,
              //         amount: route.amount ?? 0,
              //       );
              //     },
              //     child: Text(
              //       'View fare rules',
              //       style: TextStyle(
              //         fontSize: context.fs(10),
              //         fontWeight: FontWeight.w600,
              //         color: _pri,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar — Figma nodes 453:2969 / 453:2960
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(BuildContext context) {
    final route = _updatedRouteWithFareQuote ?? widget.routes.first;
    final fare = route.fareQuoteData;
    final total = fare != null
        ? _getFinalTotalDisplay(fare)
        : _convertFareAmount(
            double.tryParse(widget.totalPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
            'INR',
          );

    final paxLabel = 'FOR ${widget.travellerCount} '
        '${widget.travellerCount > 1 ? 'TRAVELLERS' : 'ADULT'}';

    return SafeArea(
      top: false,
      child: Container(
        height: context.h(80),
        padding: EdgeInsets.symmetric(horizontal: context.w(19), vertical: context.h(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          // borderRadius: BorderRadius.vertical(bottom: Radius.circular(context.r(24))),
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
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openFareBreakup(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            total,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(24),
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: -0.6,
                              height: 1.33,
                            ),
                          ),
                        ),
                        SizedBox(width: context.w(4)),
                        Icon(Icons.info_outline, size: context.w(12), color: _muted),
                      ],
                    ),
                    Text(
                      paxLabel,
                      style: TextStyle(
                        fontSize: context.fs(8),
                        fontWeight: FontWeight.w700,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: context.w(12)),
            SizedBox(
              height: context.h(44),
              width: context.w(149),
              child: ElevatedButton(
                onPressed: _submittingItinerary ? null : _validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sec,
                  disabledBackgroundColor: _sec.withValues(alpha: 0.6),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(12)),
                  ),
                ),
                child: _submittingItinerary
                    ? SizedBox(
                        width: context.w(18),
                        height: context.w(18),
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
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
  }

  /// Opens the shared Fare Breakup drawer from the bottom bar's total/info
  /// tap. Reuses the exact figures the fare-breakdown card already computes
  /// (`fareQuoteData`, add-ons, promo) — no new pricing logic.
  void _openFareBreakup(BuildContext context) {
    final route = _updatedRouteWithFareQuote ?? widget.routes.first;
    final fare = route.fareQuoteData;
    final split = _paxSplit;
    final pax = _totalPax < 1 ? 1 : _totalPax;
    final prefCurrency = di.sl<PreferencesManager>().getPreferredCurrency() ?? 'INR';

    final paxNoun = (split.children > 0 || split.infants > 0) ? 'Traveller(s)' : 'Adult(s)';
    String unitLabel(double totalForAll, String currency) =>
        '$paxNoun ($pax X ${_convertFareAmount(totalForAll / pax, currency)})';

    final lines = <FareBreakupLine>[];

    if (fare != null) {
      lines.add(FareBreakupLine(
        label: 'Base Fare',
        amount: _convertFareAmount(fare.baseFare, fare.currency),
        subLabel: unitLabel(fare.baseFare, fare.currency),
        subAmount: _convertFareAmount(fare.baseFare, fare.currency),
      ));
      lines.add(FareBreakupLine(
        label: 'Taxes & Surcharges',
        amount: _convertFareAmount(fare.tax, fare.currency),
        subLabel: unitLabel(fare.tax, fare.currency),
        subAmount: _convertFareAmount(fare.tax, fare.currency),
      ));
      if (fare.serviceFee > 0) {
        lines.add(FareBreakupLine(
          label: 'Service Fee',
          amount: _convertFareAmount(fare.serviceFee, fare.currency),
        ));
      }
      if (_addOnsTotal > 0) {
        lines.add(FareBreakupLine(
          label: 'Seat, Baggage & Meals',
          amount: _convertFareAmount(_addOnsTotal, 'INR'),
        ));
      }
      if (_promoCodeApplied && _promoDiscountAmount > 0) {
        final d = '-${CurrencyConverter.format(_promoDiscountAmount, prefCurrency)}';
        lines.add(FareBreakupLine(
          label: 'Discounts',
          amount: d,
          subLabel: _appliedPromoCode,
          subAmount: d,
          isDiscount: true,
        ));
      }
      FareBreakupSheet.show(context, lines: lines, totalAmount: _getFinalTotalDisplay(fare));
    } else {
      final est = _convertFareAmount(
        double.tryParse(widget.totalPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
        'INR',
      );
      lines.add(FareBreakupLine(
        label: 'Base Fare',
        amount: est,
        subLabel: '$pax $paxNoun',
        subAmount: est,
      ));
      FareBreakupSheet.show(context, lines: lines, totalAmount: est);
    }
  }

  /// The fare breakdown moves into a sheet behind the bottom bar's total —
  /// Figma has no inline breakdown card, but the numbers still need a home.
  // void _showFareBreakdownSheet(BuildContext context) {
  //   showModalBottomSheet<void>(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     builder: (sheetContext) => SafeArea(
  //       top: false,
  //       child: Container(
  //         margin: EdgeInsets.all(context.w(12)),
  //         padding: EdgeInsets.all(context.w(4)),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(context.r(16)),
  //         ),
  //         child: SingleChildScrollView(child: _buildFareBreakdownCard(context)),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCheckListUnavailableBanner(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.gapMedium),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.w(10)),
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
                "Couldn't verify required travel documents — showing default requirements.",
                style: TextStyle(color: const Color(0xffB45309), fontSize: context.fs(10), fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: _fetchTravelCheckList,
              child: Text('Retry', style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareBreakdownCard(BuildContext context) {
    final route = _updatedRouteWithFareQuote ?? widget.routes.first;
    final fare = route.fareQuoteData;

    if (fare == null) {
      return _buildErrorCard(
        context,
        'Could not load fare details. Using estimated price.',
      );
    }

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: _blue, size: context.iconMedium),
              SizedBox(width: context.gapSmall),
              Text(
                'Fare Breakdown',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapLarge),
          if (fare != null) ...[
            _fareRow(
              context,
              'Base Fare',
              _convertFareAmount(fare.baseFare, fare.currency),
            ),
            SizedBox(height: context.gapSmall),
            _fareRow(
              context,
              'Taxes & Fees',
              _convertFareAmount(fare.tax, fare.currency),
            ),
            if (fare.serviceFee > 0) ...[
              SizedBox(height: context.gapSmall),
              _fareRow(
                context,
                'Service Fee',
                _convertFareAmount(fare.serviceFee, fare.currency),
              ),
            ],
            if (_addOnsTotal > 0) ...[
              SizedBox(height: context.gapSmall),
              _fareRow(
                context,
                'Seat, Baggage & Meals',
                // widget.addOnsTotal is always INR (see field doc).
                _convertFareAmount(_addOnsTotal, 'INR'),
              ),
            ],
            if (_promoDiscountAmount > 0) ...[
              SizedBox(height: context.gapSmall),
              _fareRow(
                context,
                'Promo Discount',
                '- ${_getPreferredCurrencySymbol()}${_promoDiscountAmount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
            ],
            Divider(height: context.gapLarge, color: Colors.grey.shade200),
            _fareRow(
              context,
              'Total Fare',
              _getFinalTotalDisplay(fare),
              // _convertFareAmount(fare.total, fare.currency),
              isTotal: true,
            ),
          ] else ...[
            _fareRow(
              context,
              'Estimated Total',
              // totalPrice already arrives pre-formatted as "₹1,23,456" (see
              // detail_popup.dart's _formatAmount) — strip that back to a
              // number before converting/reformatting for the preferred
              // currency.
              _convertFareAmount(
                double.tryParse(widget.totalPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
                'INR',
              ),
              isTotal: true,
            ),
            SizedBox(height: context.gapSmall),
            Text(
              '*Final price will be confirmed after booking',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: context.labelSmall,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fareRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isDiscount ? Colors.green.shade700 : (isTotal ? _navy : Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isDiscount ? Colors.green.shade700 : (isTotal ? _blue : _navy),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: context.iconMedium,
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: context.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: context.iconSmall,
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Text(
              "Login to auto-fill traveller details and manage your bookings easily.",
              style: TextStyle(
                fontSize: context.fs(11),
              color: AppColors.subhead,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
              );
            },
            child: Text("Login", style: TextStyle(color: AppColors.AppBlue, fontSize: context.fs(12),),),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndProceed() async {
    if (_formKey.currentState == null ||
        !_formKey.currentState!.validateForm()) {
      print('FlightBookingScreen: Validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required passenger details'),
        ),
      );
      return;
    }

    final route = _updatedRouteWithFareQuote ?? widget.routes.first;
    final sessionId = route.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking session expired. Please search again.')),
      );
      return;
    }

    final travellers = _formKey.currentState!.getAllTravellersData();
    final lead = travellers.first;
    final travellerNames = travellers
        .map((t) => '${t['title'] ?? ''} ${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    // Seats / meals / baggage come next in the flow. SelectSeats and
    // SelectSSR must run before CreateItinerary, because they're what put
    // the add-on cost onto the server-side session that CreateItinerary
    // then prices — so the add-ons screen itself runs CreateItinerary (via
    // `_completeBooking`, passed in as `onProceed`) and pushes straight to
    // payment from its own context on Skip/Continue, instead of popping
    // back to this screen first.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeatAddonsScreen(
          route: route,
          totalPrice: widget.totalPrice,
          traceId: widget.traceId,
          resultIndex: widget.resultIndex,
          price: widget.price,
          travellerCount: _totalPax,
          adultCount: _paxSplit.adults,
          childCount: _paxSplit.children,
          infantCount: _paxSplit.infants,
          additionalLegs:
              widget.routes.length > 1 ? widget.routes.sublist(1) : const [],
          onProceed: (addOnsContext, addOns) => _completeBooking(
            addOnsContext,
            route: route,
            sessionId: sessionId,
            lead: lead,
            travellers: travellers,
            travellerNames: travellerNames,
            addOns: addOns,
          ),
        ),
      ),
    );
  }

  /// Runs CreateItinerary with the traveller details collected on this
  /// screen plus the add-on total chosen on [SeatAddonsScreen], then pushes
  /// [AkFlightPaymentScreen] from [ctx] — [SeatAddonsScreen]'s own context —
  /// so Skip/Continue land on payment directly. This never routes back
  /// through [FlightBookingScreen]: on failure it simply leaves the user on
  /// the add-ons screen to retry.
  Future<void> _completeBooking(
    BuildContext ctx, {
    required FlightRouteSegment route,
    required String sessionId,
    required Map<String, dynamic> lead,
    required List<Map<String, dynamic>> travellers,
    required List<String> travellerNames,
    required AddOnsSummary addOns,
  }) async {
    if (!mounted) return;
    setState(() => _addOnsTotal = addOns.total);

    final contactInfo = AkContactInfoRequestEntity(
      title: (lead['title'] ?? 'Mr').toString(),
      fName: (lead['firstName'] ?? '').toString(),
      lName: (lead['lastName'] ?? '').toString(),
      mobile: (lead['mobileNumber'] ?? '').toString(),
      destMob: (lead['mobileNumber'] ?? '').toString(),
      phone: '',
      email: (lead['email'] ?? '').toString(),
      // CreateItinerary requires this shape to be present, not real values —
      // the traveller form doesn't collect address/state/city/pin today.
      address: 'NA',
      // ISO two-letter country code — distinct from MobileCountryCode/
      // DestMobCountryCode below, which are phone dialing-code prefixes.
      // Akbar rejects "+91" here with "Country code must be two letter".
      countryCode: 'IN',
      mobileCountryCode: '+91',
      destMobCountryCode: '+91',
      state: 'NA',
      city: 'NA',
      pin: '000000',
      gstCompanyName: '',
      gstTIN: '',
      gstMobile: '',
      gstEmail: '',
      updateProfile: false,
      isGuest: !_isLoggedIn(),
      saveGST: false,
    );

    final akTravellers = travellers
        .map((t) => AkTravellerRequestEntity(
              title: (t['title'] ?? 'Mr').toString(),
              fName: (t['firstName'] ?? '').toString(),
              lName: (t['lastName'] ?? '').toString(),
              gender: _mapGender((t['gender'] ?? '').toString()),
              ptc: (t['paxType'] ?? 'ADT').toString().isEmpty
                  ? 'ADT'
                  : (t['paxType'] ?? 'ADT').toString(),
              dob: _toIsoDate((t['dateOfBirth'] ?? '').toString()),
              email: (t['email'] ?? '').toString(),
              pMobileNo: (t['mobileNumber'] ?? '').toString(),
            ))
        .toList();

    setState(() => _submittingItinerary = true);
    _itineraryRetried = false;

    final result = await _submitItinerary(sessionId, contactInfo, akTravellers, uiContext: ctx);

    if (!mounted) return;
    setState(() => _submittingItinerary = false);
    if (result == null || !ctx.mounted) return;

    // Add-ons → Review → Payment. The review screen is read-only and pushes
    // AkFlightPaymentScreen itself with these same arguments.
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => AkTripReviewScreen(
          route: route,
          leadPassenger: lead,
          travellers: travellers,
          netAmount: result.netAmount,
          additionalLegs: widget.routes.length > 1 ? widget.routes.sublist(1) : const [],
          travellerCount: _totalPax,
          travellerNames: travellerNames,
          addOns: addOns,
        ),
      ),
    );
  }

  /// Dispatches CreateItinerary and awaits its resolution. On
  /// `itinerary_changed`, shows a confirm dialog and retries exactly once
  /// (per the doc's caution that there's no built-in loop guard) before
  /// giving up and asking the user to tap Continue again.
  ///
  /// [uiContext] — when given — is used for the failure snackbar and the
  /// confirm dialog instead of this screen's own `context`, since by the
  /// time this runs the visible screen is [SeatAddonsScreen], not this one.
  Future<AkCreateItineraryEntity?> _submitItinerary(
    String sessionId,
    AkContactInfoRequestEntity contactInfo,
    List<AkTravellerRequestEntity> travellers, {
    BuildContext? uiContext,
  }) async {
    final feedbackContext = uiContext ?? context;
    _createItineraryBloc.add(LoadAkCreateItineraryEvent(
      AkCreateItineraryRequestEntity(
        sessionId: sessionId,
        contactInfo: contactInfo,
        travellers: travellers,
      ),
    ));

    final state = await _createItineraryBloc.stream.firstWhere(
      (s) => s is AkCreateItineraryLoaded || s is AkCreateItineraryFailed,
    );

    if (state is AkCreateItineraryFailed) {
      if (feedbackContext.mounted) {
        ScaffoldMessenger.of(feedbackContext).showSnackBar(
          SnackBar(
            content: Text(state.error.message ?? 'Could not confirm your itinerary. Please try again.'),
          ),
        );
      }
      return null;
    }

    final data = (state as AkCreateItineraryLoaded).data;
    if (!data.itineraryChanged) return data;

    if (_itineraryRetried) {
      if (feedbackContext.mounted) {
        ScaffoldMessenger.of(feedbackContext).showSnackBar(
          const SnackBar(content: Text('Your itinerary keeps changing — please tap Continue again.')),
        );
      }
      return null;
    }

    if (!feedbackContext.mounted) return null;
    final accepted = await _confirmItineraryChange(data.netAmount, uiContext: feedbackContext);
    if (!accepted) return null;

    _itineraryRetried = true;
    return _submitItinerary(sessionId, contactInfo, travellers, uiContext: uiContext);
  }

  Future<bool> _confirmItineraryChange(double newAmount, {BuildContext? uiContext}) async {
    final wantsToContinue = await showDialog<bool>(
      context: uiContext ?? context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Itinerary Updated'),
        content: Text(
          'Your total has changed to ${_convertFareAmount(newAmount, 'INR')}. Continue with this itinerary?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return wantsToContinue == true;
  }

  String _mapGender(String value) {
    final v = value.trim().toLowerCase();
    if (v.startsWith('f')) return 'F';
    if (v.startsWith('m')) return 'M';
    return 'O';
  }

  /// TravellerInformationSection stores DOB as "dd MMM yyyy" — CreateItinerary
  /// expects an ISO date ("yyyy-MM-dd").
  String _toIsoDate(String ddMmmYyyy) {
    if (ddMmmYyyy.isEmpty) return '';
    try {
      final parsed = DateFormat('dd MMM yyyy').parse(ddMmmYyyy);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return ddMmmYyyy;
    }
  }
}
