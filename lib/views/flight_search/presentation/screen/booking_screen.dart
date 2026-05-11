import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/filter_drawer.dart';
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

  double get total => offeredFare + serviceFee;

  FareQuoteData({
    required this.currency,
    required this.baseFare,
    required this.tax,
    required this.offeredFare,
    required this.publishedFare,
    required this.serviceFee,
  });
}

class FlightBookingScreen extends StatefulWidget {
  final List<FlightRouteSegment> routes;
  final String totalPrice;
  final bool isLoggedIn;
  final String? resultIndex;
  final String? traceId;
  final String price;

  const FlightBookingScreen({
    super.key,
    required this.routes,
    required this.totalPrice,
    required this.isLoggedIn,
    this.resultIndex,
    this.traceId,
    required this.price,
  });

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  late final FareQuoteBloc _fareQuoteBloc;

  final _formKey = GlobalKey<TravellerFormState>();

  DateTime? _departureDate;
  DateTime? _returnDate;

  bool _isLoadingFareQuote = false;
  String? _fareQuoteError;
  FlightRouteSegment? _updatedRouteWithFareQuote;

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
        endUserIp: '::1',
        traceId: traceId,
        tokenId: tokenId,
        resultIndex: resultIndex,
      ),
    );
  }

  @override
  void dispose() {
    print('FlightBookingScreen: Disposing bloc');
    _fareQuoteBloc.close();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isDeparture) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
        } else {
          _returnDate = picked;
        }
      });
      print(
        'FlightBookingScreen: Date picked: ${isDeparture ? 'departure' : 'return'} = $picked',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _fareQuoteBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const FlightFilterDrawer(),
        appBar: AppBar(
          title: const WanderNovaLogo(scaleFactor: 0.6),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "assets/images/wander_nova_logo.jpg",
                height: 35,
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
              SizedBox(height: context.gapLarge),
              _buildFareBreakdownCard(context),
              SizedBox(height: context.gapLarge),
              if (!widget.isLoggedIn) _buildLoginCard(context),
              SizedBox(height: context.gapLarge),

              // Traveller Information Section - Using the new widget
              TravellerInformationSection(
                formKey: _formKey,
                onDepartureDateTap: () => _pickDate(context, true),
                onReturnDateTap: () => _pickDate(context, false),
                departureDate: _departureDate,
                returnDate: _returnDate,
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
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.flight_takeoff,
                  color: Colors.indigo,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.indigoAccent,
                        size: context.iconSmall,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Fare Rules",
                        style: TextStyle(
                          color: Colors.indigoAccent,
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
                    ),
                  ),
                  SizedBox(height: 4),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.flight,
                              size: context.iconSmall,
                              color: Colors.red,
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
                  SizedBox(height: 4),
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
      padding: EdgeInsets.symmetric(horizontal: context.gapSmall, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.iconSmall, color: color),
          SizedBox(width: 4),
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
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.indigo,
                size: context.iconMedium,
              ),
              SizedBox(width: context.gapSmall),
              Text(
                'Fare Breakdown',
                style: TextStyle(
                  fontSize: context.titleMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.gapLarge),
          if (fare != null) ...[
            _fareRow(
              context,
              'Base Fare',
              '${fare.currency} ${fare.baseFare.toStringAsFixed(2)}',
            ),
            SizedBox(height: context.gapSmall),
            _fareRow(
              context,
              'Taxes & Fees',
              '${fare.currency} ${fare.tax.toStringAsFixed(2)}',
            ),
            if (fare.serviceFee > 0) ...[
              SizedBox(height: context.gapSmall),
              _fareRow(
                context,
                'Service Fee',
                '${fare.currency} ${fare.serviceFee.toStringAsFixed(2)}',
              ),
            ],
            Divider(height: context.gapLarge, color: Colors.grey.shade200),
            _fareRow(
              context,
              'Total Fare',
              '${fare.currency} ${fare.total.toStringAsFixed(2)}',
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
            color: isTotal ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? context.bodyLarge : context.bodyMedium,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? const Color(0xFFE71D36) : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.all(context.gapMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
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
      padding: EdgeInsets.all(context.gapMedium),
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
      padding: EdgeInsets.all(context.gapMedium),
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
              print('FlightBookingScreen: Login tapped');
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
  //                   endUserIp: '::1',
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
          _proceedWithoutValidation(); // Changed to bypass validation
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoadingFareQuote
              ? Colors.grey
              : const Color(0xFFE71D36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadius),
          ),
          elevation: 2,
        ),
        child: _isLoadingFareQuote
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          "Continue",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: context.bodyLarge,
          ),
        ),
      ),
    );
  }

// Add this new method to bypass validation
  void _proceedWithoutValidation() {
    print('FlightBookingScreen: Proceeding without validation');

    // Navigate directly without validation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SSRMainScreen(
          endUserIp: '::1',
          traceId: widget.traceId ?? '',
          tokenId: '',
          resultIndex: widget.resultIndex ?? '',
        ),
      ),
    );
  }

// Keep the original validation method but not using it now
  void _validateAndProceed() {
    // Validate form from the traveller section
    if (_formKey.currentState == null ||
        !_formKey.currentState!.validateForm()) {
      print('FlightBookingScreen: Validation failed');
      return;
    }

    // Get traveller data from the form
    final travellerData = _formKey.currentState!.getTravellerData();

    print('FlightBookingScreen: Validation passed, proceeding to next step');

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'traveller': travellerData,
        'route': _updatedRouteWithFareQuote ?? widget.routes.first,
        'totalPrice': widget.totalPrice,
      },
    );
  }

  // void _validateAndProceed() {
  //   // Validate form from the traveller section
  //   if (_formKey.currentState == null ||
  //       !_formKey.currentState!.validateForm()) {
  //     print('FlightBookingScreen: Validation failed');
  //     return;
  //   }
  //
  //   // Get traveller data from the form
  //   final travellerData = _formKey.currentState!.getTravellerData();
  //
  //   print('FlightBookingScreen: Validation passed, proceeding to next step');
  //
  //   Navigator.pushNamed(
  //     context,
  //     '/payment',
  //     arguments: {
  //       'traveller': travellerData,
  //       'route': _updatedRouteWithFareQuote ?? widget.routes.first,
  //       'totalPrice': widget.totalPrice,
  //     },
  //   );
  // }
}
