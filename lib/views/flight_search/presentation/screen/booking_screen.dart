import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/traveller_info_card.dart';

import '../../../../common_widgets/airline_logo.dart';
import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../MainApi/domain/entities/general_setting_entity.dart';
import '../../../MainApi/presentation/bloc/general_setting_bloc.dart';
import '../../../MainApi/presentation/bloc/general_settings_event.dart';
import '../../../MainApi/presentation/bloc/general_settings_state.dart';
import '../../../fare_quote/domain/entities/fare_quote_entity.dart';
import '../../../login/presentation/screen/login.dart';
import '../../../AKGetSPricer/domain/entity/AKGetSPricer_entity.dart';
import '../../../AKFareRule/presentation/screen/ak_fare_rule_popup.dart';
import '../../../AKTravelCheckList/domain/entity/AKTravelCheckList_entity.dart';
import '../../../AKTravelCheckList/presentation/bloc/AKTravelCheckList_bloc.dart';
import '../../../AKTravelCheckList/presentation/bloc/AKTravelCheckList_event.dart';
import '../../../AKTravelCheckList/presentation/bloc/AKTravelCheckList_state.dart';
import '../../../AKCreateItinerary/domain/entity/AKCreateItinerary_entity.dart';
import '../../../AKCreateItinerary/presentation/bloc/AKCreateItinerary_bloc.dart';
import '../../../AKCreateItinerary/presentation/bloc/AKCreateItinerary_event.dart';
import '../../../AKCreateItinerary/presentation/bloc/AKCreateItinerary_state.dart';
import '../../../flight_payment/presentation/screen/ak_payment_screen.dart';
import '../../../AKInsurance/domain/entity/AKInsurance_entity.dart';
import '../../../AKInsurance/presentation/widget/trip_secure_section.dart';

class FlightRouteSegment {
  final String from;
  final String to;
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

  const FlightBookingScreen({
    super.key,
    required this.routes,
    required this.totalPrice,
    required this.isLoggedIn,
    this.resultIndex,
    this.traceId,
    required this.price,
    this.travellerCount = 1,
  });

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  late final AkTravelCheckListBloc _checkListBloc;
  late final AkCreateItineraryBloc _createItineraryBloc;

  final _formKey = GlobalKey<TravellerFormState>();
  final _tripSecureKey = GlobalKey<TripSecureSectionState>();

  /// The Trip Secure plan the traveller opted into, or null when they
  /// declined. Purely additive to this screen — the flight itself prices and
  /// books exactly as it did before.
  AkInsurancePlanEntity? _insurancePlan;

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

  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _pageBg = Color(0xFFF3F6FC);
  static const _border = Color(0xFFE2E7F0);

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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You saved ${_getPreferredCurrencySymbol()}${discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: $promoCode',
                  style: TextStyle(
                    fontSize: 14,
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
                    child: const Text(
                      'Great!',
                      style: TextStyle(
                        fontSize: 16,
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
    double baseTotal = fare?.total ?? double.tryParse(widget.totalPrice) ?? 0;
    String originalCurrency = fare?.currency ?? 'INR';

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
      // that charge — see [_insurancePremiumInDisplayCurrency].
      final finalTotal = convertedTotal - _promoDiscountAmount;
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
    super.dispose();
  }

  Widget _buildPromoCodeSection(BuildContext context) {
    return BlocBuilder<GeneralSettingsBloc, GeneralSettingsState>(
      builder: (context, state) {
        final filtered = state is PromoCodesLoaded
            ? state.promoCodes
                .where((p) =>
                    p.category == 'flight_booking' || p.category == 'payment')
                .toList()
            : <PromoCodeEntity>[];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.r(8)),
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.w(12), context.h(12), context.w(12), 0),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_rounded,
                        color: _blue, size: context.iconMedium),
                    SizedBox(width: context.gapSmall),
                    Text(
                      'Coupons & Offers',
                      style: TextStyle(
                        fontSize: context.titleMedium,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    if (filtered.isNotEmpty && !_promoCodeApplied) ...[
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.w(8), vertical: context.h(3)),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(context.r(10)),
                        ),
                        child: Text(
                          '${filtered.length} offer${filtered.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: context.labelSmall,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: context.h(12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(12)),
                child: _promoCodeApplied
                    ? _buildPromoAppliedBanner(context)
                    : _buildPromoInputRow(context),
              ),
              if (!_promoCodeApplied && filtered.isNotEmpty) ...[
                SizedBox(height: context.h(12)),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      context.w(12), context.h(10), context.w(12), 0),
                  child: Text(
                    'AVAILABLE OFFERS',
                    style: TextStyle(
                      fontSize: context.labelSmall,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...filtered.asMap().entries.map(
                  (e) => _buildFlightCouponCard(
                      context, e.value,
                      showTopDivider: e.key > 0),
                ),
              ],
              SizedBox(height: context.h(12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromoAppliedBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade700, size: context.iconSmall),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_appliedPromoCode applied',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  'You saved ${_getPreferredCurrencySymbol()}${_promoDiscountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: context.bodySmall,
                      color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _removePromoCode,
            child: Text(
              'Remove',
              style: TextStyle(
                  color: Colors.red.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
          height: context.h(48),
          child: ElevatedButton(
            onPressed: _applyPromoCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
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

  Widget _buildFlightCouponCard(BuildContext context, PromoCodeEntity promo,
      {bool showTopDivider = false}) {
    final discountLabel = promo.discountType == 'percent'
        ? 'Get ${double.tryParse(promo.discountValue)?.toStringAsFixed(0) ?? promo.discountValue}% off on this booking'
        : 'Get ${_getPreferredCurrencySymbol()}${promo.discountValue} off on this booking';

    return Column(
      children: [
        if (showTopDivider)
          Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade100,
              indent: context.w(12),
              endIndent: context.w(12)),
        InkWell(
          onTap: () {
            _promoCodeController.text = promo.code;
            _applyPromoCode();
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.w(12), context.h(10),
                context.w(12), context.h(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(context.w(8)),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(context.r(8)),
                  ),
                  child: Icon(Icons.confirmation_number_outlined,
                      color: _blue, size: context.iconMedium),
                ),
                SizedBox(width: context.gapMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.w(8), vertical: context.h(3)),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(context.r(4)),
                          border: Border.all(
                              color: _blue.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          promo.code,
                          style: TextStyle(
                            fontSize: context.bodySmall,
                            fontWeight: FontWeight.w800,
                            color: _blue,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        discountLabel,
                        style: TextStyle(
                          fontSize: context.bodyMedium,
                          fontWeight: FontWeight.w600,
                          color: _navy,
                        ),
                      ),
                      if (promo.description.isNotEmpty)
                        Text(
                          promo.description,
                          style: TextStyle(
                              fontSize: context.bodySmall,
                              color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(8)),
                OutlinedButton(
                  onPressed: () {
                    _promoCodeController.text = promo.code;
                    _applyPromoCode();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: _blue, width: 1.5),
                    padding: EdgeInsets.symmetric(
                        horizontal: context.w(12), vertical: context.h(6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(6))),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'APPLY',
                    style: TextStyle(
                        fontSize: context.labelSmall,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
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
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          // backgroundColor: _pageBg,
          // elevation: 0,
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
        body: SingleChildScrollView(
          physics: context.scrollPhysics,
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRouteSummaryCard(context),
              SizedBox(height: context.gapSmall),
              _buildFareBreakdownCard(context),
              SizedBox(height: context.gapSmall),
              _buildPromoCodeSection(context),
              SizedBox(height: context.gapLarge),
              if (!_isLoggedIn()) _buildLoginCard(context),
              // SizedBox(height: context.gapSmall),
              _buildBookingSteps(),
              SizedBox(height: context.gapLarge),

              BlocBuilder<AkTravelCheckListBloc, AkTravelCheckListState>(
                builder: (context, checklistState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (checklistState is AkTravelCheckListLoaded &&
                          checklistState.data.unavailable)
                        _buildCheckListUnavailableBanner(context),
                      TravellerInformationSection(
                        key: _formKey,
                        isInternational: _isPassportRequired(checklistState),
                        travellerCount: widget.travellerCount,
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: context.gapLarge),
              _buildTripSecureSection(context),

              SizedBox(height: context.hp(3)),
              _buildContinueButton(context),
              SizedBox(height: context.hp(2)),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
      ),
    );
  }

  /// Trip Secure — the optional travel-insurance add-on, placed after the
  /// traveller forms so it can price against real dates of birth. It hides
  /// itself when the provider has no cover for this trip.
  Widget _buildTripSecureSection(BuildContext context) {
    final outbound = widget.routes.first;
    final inbound = widget.routes.length > 1 ? widget.routes.last : null;

    return TripSecureSection(
      key: _tripSecureKey,
      destinationAirportCode: _extractAirportCode(outbound.to),
      departureDate: _parseRouteDate(outbound.departureDate),
      returnDate: _parseRouteDate(inbound?.departureDate),
      travellerCount: widget.travellerCount,
      travellerBirthdates: _travellerBirthdates,
      onSelectionChanged: (plan) => setState(() => _insurancePlan = plan),
    );
  }

  /// Dates of birth already typed into the traveller form, as "yyyy-MM-dd".
  /// Entries are empty while a traveller card is still blank.
  List<String> _travellerBirthdates() {
    final travellers = _formKey.currentState?.getAllTravellersData() ?? const [];
    return travellers
        .map((t) => _toIsoDate((t['dateOfBirth'] ?? '').toString()))
        .toList();
  }

  /// [FlightRouteSegment.departureDate] is formatted "dd MMM yyyy" upstream.
  DateTime? _parseRouteDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return DateFormat('dd MMM yyyy').parse(value.trim());
    } catch (_) {
      return null;
    }
  }

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

  /// One leg's flight card content — extracted so [_buildRouteSummaryCard]
  /// can stack it once per entry in `widget.routes` (RT/RS: onward +
  /// return; Multi City: one per leg) instead of only ever showing
  /// `routes.first`, which is all a plain one-way booking ever has anyway.
  Widget _buildRouteLegContent(BuildContext context, FlightRouteSegment route) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AirlineLogo(
                code: route.flightNo.contains('•')
                    ? route.flightNo.split('•').first.trim()
                    : '',
                name: route.airline,
                size: context.iconMedium + context.gapSmall * 2,
                borderRadius: BorderRadius.circular(context.r(14)),
              ),
              SizedBox(width: context.gapMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.airline,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.bodyLarge,
                        color: _navy,
                      ),
                    ),
                    Text(
                      route.flightNo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: context.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  final searchTui = route.searchTui;
                  final resultIndex = widget.resultIndex ?? route.resultIndex;
                  if (searchTui == null || searchTui.isEmpty || resultIndex == null || resultIndex.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fare rules are not available for this fare.')),
                    );
                    return;
                  }
                  AkFareRulePopup.show(
                    context,
                    searchTui: searchTui,
                    resultIndex: resultIndex,
                    amount: route.amount ?? 0,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _blue,
                        size: context.iconSmall,
                      ),
                      SizedBox(width: context.w(4)),
                      Text(
                        "Fare Rules",
                        style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w600,
                          fontSize: context.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapLarge),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.departureTime,
                    style: TextStyle(
                      fontSize: context.headlineSmall,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    route.from,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: context.bodyMedium,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.gapMedium),
                  child: Column(
                    children: [
                      Text(
                        route.duration,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: context.bodySmall,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(8),
                            ),
                            child: Icon(
                              Icons.flight,
                              size: context.iconSmall,
                              color: _blue,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _stopsLabel(route),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: context.labelSmall,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    route.arrivalTime,
                    style: TextStyle(
                      fontSize: context.headlineSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    route.to,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: context.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (route.isRefundable != null || route.isHoldAllowed != null) ...[
            SizedBox(height: context.gapMedium),
            Divider(color: Colors.grey.shade200),
            SizedBox(height: context.gapSmall),
            Row(
              children: [
                if (route.isRefundable == true)
                  _buildBadge(
                    context,
                    Icons.check_circle,
                    'Refundable',
                    Colors.green,
                  ),
                if (route.isHoldAllowed == true) ...[
                  if (route.isRefundable == true)
                    SizedBox(width: context.gapSmall),
                  _buildBadge(
                    context,
                    Icons.lock_clock,
                    'Hold Allowed',
                    Colors.blue,
                  ),
                ],
              ],
            ),
          ],
        ],
    );
  }

  Widget _buildRouteSummaryCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(9),
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
          for (var i = 0; i < widget.routes.length; i++) ...[
            if (i > 0) ...[
              SizedBox(height: context.gapMedium),
              Divider(color: Colors.grey.shade200),
              SizedBox(height: context.gapMedium),
            ],
            _buildRouteLegContent(
              context,
              i == 0 ? (_updatedRouteWithFareQuote ?? widget.routes[i]) : widget.routes[i],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.gapSmall,
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.r(20)),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.iconSmall, color: color),
          SizedBox(width: context.w(4)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: context.labelSmall,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            // Shown for transparency but kept out of "Total Fare": the
            // insurance premium is not part of the flight charge this screen
            // hands to the payment step.
            if (_insurancePlan != null) ...[
              SizedBox(height: context.gapSmall),
              _fareRow(
                context,
                'Trip Secure (billed separately)',
                _convertFareAmount(_insurancePlan!.premium, _insurancePlan!.currency),
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

  Widget _buildBookingSteps() {
    const steps = [
      (Icons.flight_takeoff_rounded, 'Flight'),
      (Icons.event_seat_outlined, 'Add-ons'),
      (Icons.call_outlined, 'Contact'),
      (Icons.person_outline_rounded, 'Traveller'),
      (Icons.payments_outlined, 'Pay'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(9)),
      decoration: BoxDecoration(
        // color: Colors.white,
        // borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: context.w(34),
                    height: context.w(34),
                    decoration: BoxDecoration(
                      color: i <= 3 ? _blue : const Color(0xFFF0F3F8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      steps[i].$1,
                      size: context.w(17),
                      color: i <= 3 ? Colors.white : const Color(0xFF8A93A3),
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Text(
                    steps[i].$2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i <= 3 ? _navy : const Color(0xFF8A93A3),
                      fontSize: context.fs(11),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Container(
                width: context.w(16),
                height: context.h(1),
                color: i < 3 ? _blue.withValues(alpha: 0.45) : _border,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: context.w(20),
            height: context.w(20),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: context.gapMedium),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: context.bodyMedium,
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.all(context.w(12)),
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
            size: context.iconMedium,
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Text(
              "Login to auto-fill traveller details and manage your bookings easily.",
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade700,
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
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  // Widget _buildContinueButton(BuildContext context) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: context.buttonHeight + 10,
  //     child: ElevatedButton(
  //       onPressed: _isLoadingFareQuote
  //           ? null
  //           : () {
  //               print('FlightBookingScreen: Continue booking pressed');
  //               _validateAndProceed();
  //             },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: _isLoadingFareQuote
  //             ? Colors.grey
  //             : const Color(0xFFE71D36),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(context.borderRadius),
  //         ),
  //         elevation: 2,
  //       ),
  //       child: _isLoadingFareQuote
  //           ? SizedBox(
  //               width: 20,
  //               height: 20,
  //               child: CircularProgressIndicator(
  //                 strokeWidth: 2,
  //                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
  //               ),
  //             )
  //           : GestureDetector(
  //               onTap: () {
  //                 Navigator.push(context, MaterialPageRoute(builder: (_) => SSRMainScreen(
  //                   endUserIp: '122.161.72.69',
  //                   traceId: widget.traceId ?? '',
  //                   tokenId: '',
  //                   resultIndex: widget.resultIndex ?? '',
  //                 )));
  //               },
  //               child: Text(
  //                 "Continue",
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: context.bodyLarge,
  //                 ),
  //               ),
  //             ),
  //     ),
  //   );
  // }
  Widget _buildContinueButton(BuildContext context) {
    if (_submittingItinerary) {
      return _buildLoadingCard(context, 'Confirming your itinerary...');
    }
    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight + 10,
      child: ElevatedButton(
        onPressed: () {
          print('FlightBookingScreen: Continue booking pressed');
          _validateAndProceed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(18)),
          ),
          elevation: 0,
        ),
        child: Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: context.bodyLarge,
          ),
        ),
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
              // The form has no child/infant sub-forms today — every
              // traveller is submitted as an adult (pre-existing limitation).
              ptc: 'ADT',
              dob: _toIsoDate((t['dateOfBirth'] ?? '').toString()),
              email: (t['email'] ?? '').toString(),
              pMobileNo: (t['mobileNumber'] ?? '').toString(),
            ))
        .toList();

    setState(() => _submittingItinerary = true);
    _itineraryRetried = false;

    final result = await _submitItinerary(sessionId, contactInfo, akTravellers);

    if (!mounted) return;
    setState(() => _submittingItinerary = false);
    if (result == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AkFlightPaymentScreen(
          route: route,
          leadPassenger: lead,
          netAmount: result.netAmount,
          additionalLegs: widget.routes.length > 1 ? widget.routes.sublist(1) : const [],
          travellerCount: widget.travellerCount,
          travellerNames: travellerNames,
          // Null unless the traveller both picked a Trip Secure plan and
          // passed its KYC — the payment screen treats a null context as
          // "no insurance", so the flight-only path is unaffected.
          insuranceBookingContext: _tripSecureKey.currentState?.bookingContext,
        ),
      ),
    );
  }

  /// Dispatches CreateItinerary and awaits its resolution. On
  /// `itinerary_changed`, shows a confirm dialog and retries exactly once
  /// (per the doc's caution that there's no built-in loop guard) before
  /// giving up and asking the user to tap Continue again.
  Future<AkCreateItineraryEntity?> _submitItinerary(
    String sessionId,
    AkContactInfoRequestEntity contactInfo,
    List<AkTravellerRequestEntity> travellers,
  ) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your itinerary keeps changing — please tap Continue again.')),
        );
      }
      return null;
    }

    if (!mounted) return null;
    final accepted = await _confirmItineraryChange(data.netAmount);
    if (!accepted) return null;

    _itineraryRetried = true;
    return _submitItinerary(sessionId, contactInfo, travellers);
  }

  Future<bool> _confirmItineraryChange(double newAmount) async {
    final wantsToContinue = await showDialog<bool>(
      context: context,
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
