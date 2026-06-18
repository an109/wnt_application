import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/traveller_info_card.dart';

import '../../../../common_widgets/custom_bottom_nav.dart';
import '../../../../common_widgets/logo.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../fare_quote/domain/entities/fare_quote_entity.dart';
import '../../../fare_quote/presentation/bloc/fare_quote_bloc.dart';
import '../../../fare_quote/presentation/bloc/fare_quote_event.dart';
import '../../../fare_quote/presentation/bloc/fare_quote_state.dart';
import '../../../fare_rule/presentation/screen/fare_rules_popup.dart';
import '../../../flight_ssr/presentation/screen/ssr/main_screen.dart';
import '../../../login/presentation/screen/login.dart';

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
  late final FareQuoteBloc _fareQuoteBloc;

  final _formKey = GlobalKey<TravellerFormState>();

  bool _isLoadingFareQuote = false;
  String? _fareQuoteError;
  FlightRouteSegment? _updatedRouteWithFareQuote;
  bool _isLoggedIn() => di.sl<PreferencesManager>().isLoggedIn();

  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _pageBg = Color(0xFFF3F6FC);
  static const _border = Color(0xFFE2E7F0);

  @override
  void initState() {
    super.initState();
    print('FlightBookingScreen: Initializing FareQuoteBloc');

    _fareQuoteBloc = di.sl<FareQuoteBloc>();

    _fareQuoteBloc.stream.listen(_onFareQuoteStateChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFareQuote();
    });
  }

  void _onFareQuoteStateChange(FareQuoteState state) {
    if (state is FareQuoteLoading) {
      setState(() {
        _isLoadingFareQuote = true;
        _fareQuoteError = null;
      });
      print('FlightBookingScreen: FareQuote loading');
    } else if (state is FareQuoteLoaded) {
      setState(() {
        _isLoadingFareQuote = false;
        _fareQuoteError = null;
        if (widget.routes.isNotEmpty) {
          _updatedRouteWithFareQuote = FlightRouteSegment.fromFareQuoteEntity(
            original: widget.routes.first,
            entity: state.fareQuote,
          );
        }
      });
      print('FlightBookingScreen: FareQuote loaded successfully');
    } else if (state is FareQuoteError) {
      setState(() {
        _isLoadingFareQuote = false;
        _fareQuoteError = state.message;
      });
      print('FlightBookingScreen: FareQuote error: ${state.message}');
    }
  }

  void _fetchFareQuote() {
    print('FlightBookingScreen: Fetching FareQuote');

    final traceId = widget.traceId ?? widget.routes.firstOrNull?.traceId;
    final resultIndex =
        widget.resultIndex ?? widget.routes.firstOrNull?.resultIndex;

    if (traceId == null || traceId.isEmpty) {
      print(
        'FlightBookingScreen: traceId not available, skipping FareQuote fetch',
      );
      return;
    }
    if (resultIndex == null || resultIndex.isEmpty) {
      print(
        'FlightBookingScreen: resultIndex not available, skipping FareQuote fetch',
      );
      return;
    }

    final prefs = di.sl<PreferencesManager>();
    final tokenId = prefs.getToken() ?? '';

    print(
      'FlightBookingScreen: Calling FareQuote with traceId=$traceId, resultIndex=$resultIndex',
    );

    _fareQuoteBloc.add(
      FetchFareQuote(
        endUserIp: '122.161.72.69',
        traceId: traceId,
        tokenId: tokenId,
        resultIndex: resultIndex,
      ),
    );
  }

  bool get _isInternationalRoute {
    if (widget.routes.isEmpty) return false;
    final route = widget.routes.first;
    final fromCode = _extractAirportCode(route.from);
    final toCode = _extractAirportCode(route.to);
    return !_indianAirportCodes.contains(fromCode) ||
        !_indianAirportCodes.contains(toCode);
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
    print('FlightBookingScreen: Disposing bloc');
    _fareQuoteBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _fareQuoteBloc,
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
              SizedBox(height: context.gapLarge),
              if (!_isLoggedIn()) _buildLoginCard(context),
              // SizedBox(height: context.gapSmall),
              _buildBookingSteps(),
              SizedBox(height: context.gapLarge),

              TravellerInformationSection(
                key: _formKey,
                isInternational: _isInternationalRoute,
                travellerCount: widget.travellerCount,
              ),

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

  Widget _buildRouteSummaryCard(BuildContext context) {
    final route = _updatedRouteWithFareQuote ?? widget.routes.first;

    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        // color: Colors.white,
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.gapSmall),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(context.r(14)),
                ),
                child: Icon(
                  Icons.flight_takeoff,
                  color: _blue,
                  size: context.iconMedium,
                ),
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
                  print('FlightBookingScreen: Fare Rules tapped');
                  FareRulePopup.show(
                    context: context,
                    traceId: widget.traceId ?? route.traceId,
                    resultIndex: widget.resultIndex ?? route.resultIndex,
                    routes: widget.routes,
                    price: widget.price,
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
                        "Direct Flight",
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

    if (fare == null && _isLoadingFareQuote) {
      return _buildLoadingCard(context, 'Fetching fare details...');
    }

    if (fare == null && _fareQuoteError != null) {
      return _buildErrorCard(
        context,
        'Could not load fare details. Using estimated price.',
      );
    }

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        // color: Colors.white,
        // borderRadius: BorderRadius.circular(8),
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
            Divider(height: context.gapLarge, color: Colors.grey.shade200),
            _fareRow(
              context,
              'Total Fare',
              _convertFareAmount(fare.total, fare.currency),
              isTotal: true,
            ),
          ] else ...[
            _fareRow(
              context,
              'Estimated Total',
              '₹${widget.totalPrice}',
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? _navy : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? _blue : _navy,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSteps() {
    const steps = [
      (Icons.flight_takeoff_rounded, 'Flight'),
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
                      color: i <= 2 ? _blue : const Color(0xFFF0F3F8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      steps[i].$1,
                      size: context.w(17),
                      color: i <= 2 ? Colors.white : const Color(0xFF8A93A3),
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Text(
                    steps[i].$2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i <= 2 ? _navy : const Color(0xFF8A93A3),
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
                color: i < 2 ? _blue.withValues(alpha: 0.45) : _border,
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
    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight + 10,
      child: ElevatedButton(
        onPressed: _isLoadingFareQuote
            ? null
            : () {
                print('FlightBookingScreen: Continue booking pressed');
                _validateAndProceed();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoadingFareQuote ? Colors.grey : _blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(18)),
          ),
          elevation: 0,
        ),
        child: _isLoadingFareQuote
            ? SizedBox(
                width: context.w(20),
                height: context.w(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
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

  void _validateAndProceed() {
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

    final travellerData = _formKey.currentState!.getTravellerData();
    final route = _updatedRouteWithFareQuote ?? widget.routes.first;

    print('FlightBookingScreen: Validation passed — navigating to SSR screen');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SSRMainScreen(
          endUserIp: '122.161.72.69',
          traceId: widget.traceId ?? route.traceId ?? '',
          tokenId: '',
          resultIndex: widget.resultIndex ?? route.resultIndex ?? '',
          passengerData: travellerData,
          fareQuoteData: route.fareQuoteData,
          route: route,
          travellerCount: widget.travellerCount,
        ),
      ),
    );
  }
}
