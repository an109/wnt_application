import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../flight_payment/data/razorpay_custom_checkout_service.dart';
import '../../../wallet/data/data_source/wallet_api_service.dart';
import '../../../wallet/wallet/screen/checkout/card_form.dart';
import '../../../wallet/wallet/screen/checkout/checkout_ui.dart';
import '../../../wallet/wallet/screen/checkout/method_sections.dart';
import '../../../wallet/wallet/screen/checkout/upi_section.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/TReservation-entity.dart';
import '../../domain/usecase/TReservation_usecase.dart';
import 'booking_confirmation_screen.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';


class PaymentScreen extends StatefulWidget {
  final String resultId;
  final String searchId;
  final String vehicleType;
  final String vehicleName;
  final String providerName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime pickupDate;
  final int passengers;

  /// Trip type and return date/time as chosen on the search/booking
  /// screens — this screen no longer lets the user change them, it just
  /// carries what was already decided through to the reservation.
  final bool isOneWay;
  final DateTime? returnDate;
  final double baseFare;
  final double totalAmount;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;
  final int? userId;

  /// Flight details captured on the booking form. Mozio requires non-blank
  /// `airline` and `flight_number` on every reservation.
  final String flightNumber;
  final String airline;

  /// Return-leg flight details — Mozio also requires these whenever the
  /// booking is a round trip (blank for one-way).
  final String returnFlightNumber;
  final String returnAirline;

  /// Supplier add-ons the customer ticked on the booking screen (amenity
  /// keys), the coupon they applied, and the amounts — all in INR, which is
  /// what this screen charges in. [totalAmount] already includes add-ons and
  /// is net of [discountAmount].
  final List<String> optionalAmenityKeys;
  final double addOnsAmount;
  final double discountAmount;
  final String? couponCode;

  /// Purely cosmetic (Figma ride-summary card): the vehicle photo and the
  /// passenger's gender initial. Both optional — the card falls back to a
  /// generic car icon / no gender suffix when not supplied.
  final String vehicleImageUrl;
  final String? passengerGender;

  const PaymentScreen({
    super.key,
    required this.resultId,
    required this.searchId,
    required this.vehicleType,
    required this.vehicleName,
    required this.providerName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupDate,
    required this.passengers,
    this.isOneWay = true,
    this.returnDate,
    required this.baseFare,
    required this.totalAmount,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
    required this.userId,
    required this.flightNumber,
    required this.airline,
    this.returnFlightNumber = '',
    this.returnAirline = '',
    this.optionalAmenityKeys = const [],
    this.addOnsAmount = 0,
    this.discountAmount = 0,
    this.couponCode,
    this.vehicleImageUrl = '',
    this.passengerGender,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // ---- Figma tokens (same palette as AkFlightPaymentScreen) ----
  static const _pri = AppColors.AppBlue;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);
  static const _offer = Color(0xFF16A34A);

  String? _selectedPaymentMethod;
  String? _selectedTileId;
  bool _isProcessing = false;
  String _statusMessage = 'Processing your payment...';
  String? _errorMessage;

  // Inline accordion payment sections
  String? _open;
  final _rzService = RazorpayCustomCheckoutService();
  late final Future<List<UpiApp>> _upiApps = _rzService.getUpiApps().catchError((_) => <UpiApp>[]);
  Future<Map<String, dynamic>>? _methods;

  // Trip type chosen by the user — drives TransportReservationEntity.tripType.
  String _tripType = 'one_way'; // 'one_way' | 'round_trip'
  DateTime? _returnDate; // required when _tripType == 'round_trip'

  static const _successGreen = Color(0xff10B981);

  // ---- Razorpay Custom Checkout (native Android SDK bridge, same as
  // AkFlightPaymentScreen) ----

  /// Set once the first Custom Checkout attempt creates an order, then
  /// reused by every method screen (card/UPI/netbanking/wallet provider) —
  /// an order must be created exactly once and ties to one successful
  /// payment, so this is memoized rather than re-created per tile tap.
  String? _razorpayOrderId;
  String? _razorpayKeyId;

  // Set once /wallet/pay-booking/ has charged the wallet for this booking, so
  // it is never charged twice.
  String? _walletDebitRef;

  /// Cosmetic checkout-hold countdown (Figma header) — purely visual, never
  /// blocks payment. Matches the 15-minute hold shown on the Ak flight
  /// payment screen, without adopting its expiry-gating behaviour here.
  static const _holdDuration = Duration(minutes: 15);
  Timer? _holdTimer;
  Duration _timeLeft = _holdDuration;
  String get _minutes => _timeLeft.inMinutes.toString().padLeft(2, '0');
  String get _seconds => (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _tripType = widget.isOneWay ? 'one_way' : 'round_trip';
    _returnDate = widget.returnDate;
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft.inSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _timeLeft -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  /// [gateway] is how the booking was actually paid ('razorpay' | 'wallet').
  /// It must not come from [_selectedPaymentMethod]: Razorpay methods never
  /// set that, so a card/UPI payment would be recorded with no gateway (or
  /// as 'wallet' after an earlier wallet tap).
  TransportReservationEntity _buildReservationEntity({
    required String gateway,
    required String paymentReferenceId,
    String razorpayOrderId = '',
    String razorpayPaymentId = '',
  }) {
    print('BUILDING RESERVATION ENTITY');

    final nameParts = widget.passengerName.split(' ');
    final firstName = nameParts[0];
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Add-ons chosen on the booking screen, plus the existing payment marker.
    final optionalAmenities = <String>[...widget.optionalAmenityKeys];
    if (gateway == 'razorpay') {
      optionalAmenities.add('razorpay_payment');
    }

    final entity = TransportReservationEntity(
      searchId: widget.searchId,
      resultId: widget.resultId,
      firstName: firstName,
      email: widget.passengerEmail,
      phoneNumber: widget.passengerPhone,
      customerInfo: CustomerInfoEntity(
        firstName: firstName,
        lastName: lastName,
        email: widget.passengerEmail,
        phoneNumber: widget.passengerPhone,
      ),
      passengers: [
        PassengerEntity(
          firstName: firstName,
          lastName: lastName,
          email: widget.passengerEmail,
        ),
      ],
      numPassengers: widget.passengers,
      currency: 'USD',
      selectedCurrency: 'INR',
      displayCurrency: 'INR',
      displayTotalPrice: widget.totalAmount,
      displayBasePrice: widget.baseFare,
      displayRideBasePrice: widget.baseFare,
      displayDiscountAmount: widget.discountAmount,
      optionalAmenities: optionalAmenities,
      userId: widget.userId ?? 123,
      guestReference: null,
      tripStartAddress: widget.pickupLocation,
      tripEndAddress: widget.dropoffLocation,
      tripPickupDatetime: widget.pickupDate.toIso8601String(),
      tripPickupDatetimePretty: _formatDateTime(widget.pickupDate),
      tripReturnPickupDatetime: _tripType == 'round_trip' && _returnDate != null
          ? _returnDate!.toIso8601String()
          : '',
      tripReturnPickupDatetimePretty:
          _tripType == 'round_trip' && _returnDate != null
          ? _formatDateTime(_returnDate!)
          : '',
      tripType: _tripType,
      vehicleName: widget.vehicleName,
      providerName: widget.providerName,
      paidVia: gateway,
      paymentGateway: gateway,
      paymentReferenceId: paymentReferenceId,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      specialInstructions: '',
      notes: '',
      // Real flight details captured on the booking form. Mozio requires these
      // non-blank on every reservation.
      flightNumber: widget.flightNumber,
      airline: widget.airline,
      // Mozio also requires the return leg's flight details on a round trip.
      returnFlightNumber: _tripType == 'round_trip' ? widget.returnFlightNumber : '',
      returnAirline: _tripType == 'round_trip' ? widget.returnAirline : '',
      couponCode: widget.couponCode,
      extraPaxInfo: null,
    );

    print('Reservation entity built successfully');
    print('Result ID: ${entity.resultId}');
    print('Total Price: ${entity.displayTotalPrice}');
    print('Payment Method: ${entity.paidVia}');

    return entity;
  }

  /// Creates the transport reservation AFTER a successful payment. This is the
  /// step that actually calls `Urls.transportReservations` — without it the
  /// payment goes through but no booking is ever recorded. Same payment
  /// fields as the website: Razorpay → the order's reference_id plus both
  /// Razorpay ids; wallet → the pay-booking debit's reference.
  Future<void> _createReservation({
    required String gateway,
    required String paymentReferenceId,
    String razorpayOrderId = '',
    String razorpayPaymentId = '',
  }) async {
    final entity = _buildReservationEntity(
      gateway: gateway,
      paymentReferenceId: paymentReferenceId,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
    );
    print('=== CREATING TRANSPORT RESERVATION (ref=$paymentReferenceId) ===');

    try {
      final result = await di.sl<CreateTransportReservationUseCase>()(
        searchId: entity.searchId,
        resultId: entity.resultId,
        firstName: entity.firstName,
        email: entity.email,
        phoneNumber: entity.phoneNumber,
        customerInfo: entity.customerInfo,
        passengers: entity.passengers,
        numPassengers: entity.numPassengers,
        currency: entity.currency,
        selectedCurrency: entity.selectedCurrency,
        displayCurrency: entity.displayCurrency,
        displayTotalPrice: entity.displayTotalPrice,
        displayBasePrice: entity.displayBasePrice,
        displayRideBasePrice: entity.displayRideBasePrice,
        displayDiscountAmount: entity.displayDiscountAmount,
        optionalAmenities: entity.optionalAmenities,
        tripStartAddress: entity.tripStartAddress,
        tripEndAddress: entity.tripEndAddress,
        tripPickupDatetime: entity.tripPickupDatetime,
        tripReturnPickupDatetime: entity.tripReturnPickupDatetime,
        tripReturnPickupDatetimePretty: entity.tripReturnPickupDatetimePretty,
        tripType: entity.tripType,
        vehicleName: entity.vehicleName,
        providerName: entity.providerName,
        paidVia: entity.paidVia,
        paymentGateway: entity.paymentGateway,
        paymentReferenceId: entity.paymentReferenceId,
        razorpayOrderId: entity.razorpayOrderId,
        razorpayPaymentId: entity.razorpayPaymentId,
        specialInstructions: entity.specialInstructions,
        notes: entity.notes,
        flightNumber: entity.flightNumber,
        airline: entity.airline,
        returnFlightNumber: entity.returnFlightNumber,
        returnAirline: entity.returnAirline,
        couponCode: entity.couponCode,
        extraPaxInfo: entity.extraPaxInfo,
      );

      if (!mounted) return;
      if (result is DataSuccess<TransportReservationEntity>) {
        print('Reservation created: resultId=${result.data?.resultId}');
        // Show the booking confirmation screen. Use the locally built entity
        // (it carries the full trip/passenger/flight details) and the payment
        // reference. pushReplacement so the user can't go back into payment.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              // Local entity carries the full trip/passenger details; status &
              // confirmation come from the live reservation response.
              reservation: entity,
              status: result.data?.status ?? '',
              confirmationNumber: result.data?.confirmationNumber ?? '',
            ),
          ),
        );
      } else {
        print('Reservation failed: ${result.error?.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment succeeded but the booking could not be created. '
              'Please contact support with your payment reference.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('Reservation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment succeeded but the booking could not be created. '
            'Please contact support.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==================================================================
  // BUILD
  // ==================================================================
  @override
  Widget build(BuildContext context) {
    print('PAYMENT SCREEN BUILD CALLED');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Divider(height: 1, color: _stroke),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(18), context.w(16), context.h(32)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _totalDue(context),
                    SizedBox(height: context.h(16)),
                    _rideDetailCard(context, includePassenger: true),
                    SizedBox(height: context.h(20)),
                    // _buildTripTypeSection(),
                    // SizedBox(height: context.h(20)),
                    if (_isProcessing) ...[
                      _processingCard(context),
                    ] else ...[
                      if (_errorMessage != null) ...[
                        _errorBanner(context, _errorMessage!),
                        SizedBox(height: context.h(16)),
                      ],
                      _emiPromoCard(context),
                      _optionCard(context, children: [
                        _optionRow(
                          context,
                          tileId: 'wallet',
                          method: 'wallet',
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: const Color(0xFF16A34A),
                          iconBg: const Color(0xFFECFDF5),
                          title: 'My Wallet',
                          subtitle: 'Pay using your wallet balance',
                        ),
                      ]),
                      _sectionLabel(context, 'Pay Online'),
                      SizedBox(height: context.h(10)),
                      _googlePayTile(context),
                      SizedBox(height: context.h(8)),
                      CheckoutAccordion(
                        title: 'UPI',
                        subtitle: 'Google Pay, PhonePe, Paytm & more',
                        badge: 'INSTANT',
                        leading: const CheckoutIcon('assets/NewIcons/upi.png'),
                        expanded: _open == 'upi',
                        onTap: () => _toggle('upi'),
                        child: _open == 'upi' ? UpiSection(
                          amount: widget.totalAmount,
                          busy: _isProcessing,
                          apps: _upiApps,
                          onPayWithApp: (app) => _payWithMethod({'method': 'upi', '_[flow]': 'intent', 'upi_app_package_name': app.package}),
                          onPayWithVpa: (vpa) => _payWithMethod({'method': 'upi', '_[flow]': 'collect', 'vpa': vpa}),
                        ) : const SizedBox.shrink(),
                      ),
                      CheckoutAccordion(
                        title: 'Credit / Debit Card',
                        subtitle: 'Visa, Mastercard, RuPay, Amex & more',
                        leading: const CheckoutIcon('assets/NewIcons/credit.png'),
                        expanded: _open == 'card',
                        onTap: () => _toggle('card'),
                        child: _open == 'card' ? CardForm(
                          payLabel: 'Pay ${formatInr(widget.totalAmount)}',
                          busy: _isProcessing,
                          onSubmit: (card) => _payWithMethod({'method': 'card', 'card': card}),
                        ) : const SizedBox.shrink(),
                      ),
                      CheckoutAccordion(
                        title: 'Net Banking',
                        subtitle: 'All major banks available',
                        leading: const CheckoutIcon('assets/NewIcons/net_banking.png'),
                        expanded: _open == 'netbanking',
                        onTap: () => _toggle('netbanking'),
                        child: _open == 'netbanking' ? NetbankingSection(
                          amount: widget.totalAmount,
                          busy: _isProcessing,
                          methods: _loadMethods(),
                          onPay: (bank) => _payWithMethod({'method': 'netbanking', 'bank': bank}),
                        ) : const SizedBox.shrink(),
                      ),
                      CheckoutAccordion(
                        title: 'EMI',
                        subtitle: 'Easy monthly instalments on credit cards',
                        leading: _emiIcon(context),
                        expanded: _open == 'emi',
                        onTap: () => _toggle('emi'),
                        child: _open == 'emi' ? EmiSection(
                          amount: widget.totalAmount,
                          busy: _isProcessing,
                          methods: _loadMethods(),
                          onPay: (months, card) => _payWithMethod({'method': 'emi', 'emi_duration': months, 'card': card}),
                        ) : const SizedBox.shrink(),
                      ),
                      CheckoutAccordion(
                        title: 'Wallets & Pay Later',
                        subtitle: 'Paytm, PhonePe, Amazon Pay · LazyPay, Simpl & more',
                        leading: const CheckoutIcon('assets/NewIcons/wallet.png'),
                        expanded: _open == 'wallet',
                        onTap: () => _toggle('wallet'),
                        child: _open == 'wallet' ? WalletsPayLaterSection(
                          amount: widget.totalAmount,
                          busy: _isProcessing,
                          methods: _loadMethods(),
                          onPayWallet: (w) => _payWithMethod({'method': 'wallet', 'wallet': w}),
                          onPayLater: (p) => _payWithMethod({'method': 'paylater', 'provider': p}),
                        ) : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _header(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isProcessing ? null : () => Navigator.of(context).maybePop(),
            child: Icon(Icons.arrow_back_rounded, size: context.w(22), color: Colors.black),
          ),
          SizedBox(width: context.w(15)),
          Expanded(
            child: Text(
              'Payment',
              style: TextStyle(
                fontSize: context.fs(20),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Icon(Icons.timer, size: context.w(16), color: _pri),
          SizedBox(width: context.w(4)),
          Text(
            '$_minutes:$_seconds',
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w600,
              color: _pri,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TOTAL DUE ====================
  Widget _totalDue(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showFareTopSheet(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total Due',
              style: TextStyle(
                fontSize: context.fs(22),
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            '₹ ${_amount(widget.totalAmount)}',
            style: TextStyle(
              fontSize: context.fs(22),
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          SizedBox(width: context.w(4)),
          Icon(Icons.keyboard_arrow_down_rounded, size: context.w(22), color: _pri),
        ],
      ),
    );
  }

  String _amount(double v) {
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    final parts = s.split('.');
    final whole =
        parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  /// Fare breakup as a drawer that slides down from the TOP, mirroring
  /// [AkFlightPaymentScreen._showFareTopSheet] exactly (same gradient,
  /// corners, close affordance and dismiss behaviour).
  Future<void> _showFareTopSheet(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fare breakup',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, _, __) =>
          Align(alignment: Alignment.topCenter, child: _fareTopSheet(ctx)),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(curved),
          child: child,
        );
      },
    );
  }

  Widget _fareTopSheet(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFF80DAFF)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(context.r(24)),
                bottomRight: Radius.circular(context.r(24)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(24), context.w(16), context.h(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(context).maybePop(),
                                child: Icon(Icons.arrow_back_rounded,
                                    size: context.w(20), color: Colors.black),
                              ),
                              SizedBox(width: context.w(15)),
                              Expanded(
                                child: Text(
                                  'Payment',
                                  style: TextStyle(
                                    fontSize: context.fs(20),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Icon(Icons.timer, size: context.w(16), color: _pri),
                              SizedBox(width: context.w(4)),
                              Text(
                                '$_minutes:$_seconds',
                                style: TextStyle(
                                  fontSize: context.fs(14),
                                  fontWeight: FontWeight.w600,
                                  color: _pri,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(24)),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total Due',
                                  style: TextStyle(
                                    fontSize: context.fs(22),
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                              ),
                              Text(
                                '₹ ${_amount(widget.totalAmount)}',
                                style: TextStyle(
                                  fontSize: context.fs(22),
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              SizedBox(width: context.w(4)),
                              Icon(Icons.keyboard_arrow_up_rounded,
                                  size: context.w(22), color: _pri),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.h(14)),
                    _fareLine(context, 'Fare', '₹${_amount(widget.baseFare)}'),
                    if (widget.addOnsAmount > 0) ...[
                      SizedBox(height: context.h(14)),
                      _fareLine(context, 'Add-ons', '+ ₹${_amount(widget.addOnsAmount)}'),
                    ],
                    if (widget.discountAmount > 0) ...[
                      SizedBox(height: context.h(14)),
                      _fareLine(
                        context,
                        widget.couponCode != null && widget.couponCode!.isNotEmpty
                            ? 'Discount (${widget.couponCode})'
                            : 'Discount',
                        '- ₹${_amount(widget.discountAmount)}',
                      ),
                    ],
                    SizedBox(height: context.h(14)),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.w(10), vertical: context.h(3)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(context.r(999)),
                          border: Border.all(color: _pri),
                        ),
                        child: Text(
                          _tripType == 'round_trip' ? 'Airport Round Trip' : 'Airport One Way',
                          style: TextStyle(
                            fontSize: context.fs(9),
                            fontWeight: FontWeight.w700,
                            color: _pri,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(14)),
                    _rideDetailCard(context, includePassenger: false),
                    SizedBox(height: context.h(14)),
                    _locationBreakdown(context),
                    SizedBox(height: context.h(14)),
                    _passengerCard(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.h(12)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: context.w(38),
            height: context.w(38),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.close_rounded, size: context.w(20), color: _ink),
          ),
        ),
      ],
    );
  }

  Widget _fareLine(BuildContext context, String label, String amount) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: _ink, fontSize: context.fs(13), fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            child: Container(height: 0.6, color: AppColors.lightsubhead),
          ),
        ),
        Text(
          amount,
          style: TextStyle(color: _ink, fontSize: context.fs(13), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ==================== RIDE DETAIL CARD ====================
  /// "Delhi Airport ⇄ Gurgaon" card — car photo, route, vehicle-type badge,
  /// pickup/drop lines, and (in the collapsed main-body view only) the
  /// passenger name. Reused, unchanged, inside the expanded fare sheet, just
  /// without the passenger row (that becomes its own [_passengerCard] there).
  Widget _rideDetailCard(BuildContext context, {required bool includePassenger}) {
    final dropOn = _tripType == 'round_trip' ? _returnDate : null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.w(48),
                height: context.w(48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: widget.vehicleImageUrl.isEmpty
                    ? Icon(Icons.directions_car_rounded,
                        size: context.w(26), color: Colors.grey.shade400)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(context.r(10)),
                        child: CachedNetworkImage(
                          imageUrl: widget.vehicleImageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Icon(Icons.directions_car_rounded,
                              size: context.w(26), color: Colors.grey.shade400),
                        ),
                      ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(widget.pickupLocation,
                              style: TextStyle(
                                  fontSize: context.fs(13),
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.w(6)),
                            child: Icon(Icons.swap_horiz_rounded,
                                size: context.w(15), color: _pri),
                          ),
                          Text(widget.dropoffLocation,
                              style: TextStyle(
                                  fontSize: context.fs(13),
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                        ],
                      ),
                    ),
                    if (widget.vehicleType.isNotEmpty) ...[
                      SizedBox(width: context.w(8)),
                      _vehicleTypeBadge(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Divider(height: 1, color: _stroke),
          SizedBox(height: context.h(10)),
          _bulletDateLine(context, 'Pickup on', widget.pickupDate),
          if (dropOn != null) ...[
            SizedBox(height: context.h(4)),
            _bulletDateLine(context, 'Drop on', dropOn),
          ],
          if (includePassenger) ...[
            SizedBox(height: context.h(10)),
            Divider(height: 1, color: _stroke),
            SizedBox(height: context.h(8)),
            Text(
              _passengerLine,
              style: TextStyle(
                fontSize: context.fs(11),
                fontWeight: FontWeight.w600,
                color: _muted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _passengerLine {
    final gender = (widget.passengerGender ?? '').trim();
    final gi = gender.isNotEmpty ? ' (${gender[0].toUpperCase()})' : '';
    return '${widget.passengerName.toUpperCase()}$gi';
  }

  Widget _vehicleTypeBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(10), vertical: context.h(4)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(20)),
        gradient: const LinearGradient(colors: [Color(0xff7AD3F7), AppColors.AppBlue]),
      ),
      child: Text(
        widget.vehicleType.toUpperCase(),
        style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Widget _bulletDateLine(BuildContext context, String label, DateTime date) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: context.h(5)),
          child: Container(
            width: context.w(4),
            height: context.w(4),
            decoration: BoxDecoration(color: _muted, shape: BoxShape.circle),
          ),
        ),
        SizedBox(width: context.w(6)),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontSize: context.fs(11), color: _muted),
                ),
                TextSpan(
                  text: _formatDateTime(date),
                  style: TextStyle(
                      fontSize: context.fs(11), color: _ink, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// "Start & return to / Travel to" (round trip) or "Pickup / Drop" (one
  /// way) location breakdown inside the expanded sheet — same connector
  /// asset [TransportBookingCard] uses for its own trip-type rows.
  Widget _locationBreakdown(BuildContext context) {
    final isRoundTrip = _tripType == 'round_trip';
    final startLabel = isRoundTrip ? 'Start & return to:' : 'Pickup:';
    final endLabel = isRoundTrip ? 'Travel to:' : 'Drop:';
    final connectorAsset =
        isRoundTrip ? 'assets/Newimage/Rlocate.png' : 'assets/Newimage/locate.png';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(connectorAsset, width: context.w(22), fit: BoxFit.fill),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(startLabel,
                    style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: _ink)),
                SizedBox(height: context.h(2)),
                Text(widget.pickupLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(11), color: _muted)),
                SizedBox(height: context.h(14)),
                Text(endLabel,
                    style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w700, color: _ink)),
                SizedBox(height: context.h(2)),
                Text(widget.dropoffLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(11), color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Passenger card inside the fare drawer — "ANJLI SINGH (F)" + email/phone.
  Widget _passengerCard(BuildContext context) {
    final contact = [
      if (widget.passengerEmail.isNotEmpty) widget.passengerEmail,
      if (widget.passengerPhone.isNotEmpty) widget.passengerPhone,
    ].join(' I ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.white, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _passengerLine.isEmpty ? 'Guest' : _passengerLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: context.fs(13), fontWeight: FontWeight.w800, color: _ink, letterSpacing: 0.3),
          ),
          if (contact.isNotEmpty) ...[
            SizedBox(height: context.h(3)),
            Text(contact, style: TextStyle(fontSize: context.fs(11), color: _muted)),
          ],
        ],
      ),
    );
  }

  // ==================== TRIP TYPE (unchanged behaviour, restyled) ====================
  Future<void> _pickReturnDateTime() async {
    final base = _returnDate ??
        widget.pickupDate.add(const Duration(hours: 2));
    final initial = base.isBefore(widget.pickupDate) ? widget.pickupDate : base;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.pickupDate,
      lastDate: widget.pickupDate.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _returnDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Widget _buildTripTypeSection() {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Type',
            style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w700, color: _ink),
          ),
          SizedBox(height: context.h(10)),
          Row(
            children: [
              Expanded(
                child: _buildTripTypeOption(
                  label: 'One Way',
                  icon: Icons.arrow_forward,
                  value: 'one_way',
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: _buildTripTypeOption(
                  label: 'Round Trip',
                  icon: Icons.compare_arrows,
                  value: 'round_trip',
                ),
              ),
            ],
          ),
          if (_tripType == 'round_trip') ...[
            SizedBox(height: context.h(14)),
            Text(
              'RETURN PICKUP',
              style: TextStyle(
                fontSize: context.fs(10),
                fontWeight: FontWeight.w700,
                color: _muted,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: context.h(8)),
            InkWell(
              onTap: _pickReturnDateTime,
              borderRadius: BorderRadius.circular(context.r(8)),
              child: Container(
                padding: EdgeInsets.all(context.w(12)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.r(8)),
                  border: Border.all(
                    color: _returnDate == null ? _stroke : _pri,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: context.w(15), color: _pri),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: Text(
                        _returnDate == null
                            ? 'Select return date & time'
                            : _formatDateTime(_returnDate!),
                        style: TextStyle(
                          fontSize: context.fs(13),
                          color: _returnDate == null ? _muted : _ink,
                          fontWeight: _returnDate == null ? FontWeight.w400 : FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: context.w(16), color: _muted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripTypeOption({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _tripType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tripType = value;
          if (value == 'one_way') _returnDate = null;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.h(10)),
        decoration: BoxDecoration(
          color: isSelected ? _pri.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(
            color: isSelected ? _pri : _stroke,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: context.w(14), color: isSelected ? _pri : Colors.grey.shade600),
            SizedBox(width: context.w(6)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(13),
                fontWeight: FontWeight.w600,
                color: isSelected ? _pri : _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== OPTIONS ====================
  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600, color: Colors.black),
      );

  Widget _emiPromoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(12)),
            color: _offer.withValues(alpha: 0.06),
            child: Row(
              children: [
                Icon(Icons.percent_rounded, size: context.w(16), color: _offer),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Text(
                    'Get an additional Rs 300 off with HDFCEMI on 6 month EMI.',
                    style: TextStyle(
                        fontSize: context.fs(12), fontWeight: FontWeight.w600, color: _ink, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          _optionRow(
            context,
            tileId: 'emi',
            interactive: false,
            icon: Icons.calendar_view_week_rounded,
            iconColor: _pri,
            iconBg: const Color(0xFFEFF6FF),
            title: 'EMI',
            subtitle: 'Credit/Debit Card & Cardless EMI available',
            tag: 'NO COST EMI',
            tagColor: _pri,
          ),
        ],
      ),
    );
  }

  Widget _optionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _promoStrip(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(12)),
      padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: _offer.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _offer.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.discount_rounded, size: context.w(18), color: _offer),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: _ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  /// One payment option ROW. Tapping an interactive row selects the method
  /// and starts payment immediately — no separate Pay button on this screen,
  /// same one-tap pattern [AkFlightPaymentScreen] uses.
  Widget _optionRow(
    BuildContext context, {
    required String tileId,
    String? method, // 'wallet' — what _processPayment runs
    VoidCallback? onTapOverride, // Custom Checkout methods route here instead
    IconData? icon,
    String? iconAsset,
    Color iconColor = Colors.transparent,
    Color iconBg = const Color(0xFFF1F5F9),
    required String title,
    required String subtitle,
    String? tag,
    Color tagColor = _offer,
    bool interactive = true,
  }) {
    final isSelected = interactive && _selectedTileId == tileId;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(14)),
      color: isSelected ? _pri.withValues(alpha: 0.05) : Colors.white,
      child: Row(
        children: [
          iconAsset != null
              ? Image.asset(iconAsset, width: context.w(34), height: context.w(34))
              : Container(
                  width: context.w(34),
                  height: context.w(34),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(context.r(8))),
                  child: Icon(icon, size: context.w(18), color: iconColor == Colors.transparent ? _ink : iconColor),
                ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: _ink),
                      ),
                    ),
                    if (tag != null) ...[
                      SizedBox(width: context.w(6)),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: context.w(6), vertical: context.h(2)),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(context.r(4)),
                          ),
                          child: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: context.fs(9), fontWeight: FontWeight.w800, color: tagColor, letterSpacing: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.h(3)),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(12), color: _muted),
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(8)),
          if (interactive)
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              size: context.w(22),
              color: isSelected ? _pri : AppColors.AppBlue,
            ),
        ],
      ),
    );

    if (!interactive || (method == null && onTapOverride == null)) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isProcessing ? null : (onTapOverride ?? () => _payWith(method!, tileId)),
      child: content,
    );
  }

  /// One-tap: remember the method, then run the existing payment routing —
  /// only 'wallet' still uses this; every Custom Checkout method routes via
  /// its own [onTapOverride] instead.
  void _payWith(String method, String tileId) {
    if (_isProcessing) return;
    if (_tripType == 'round_trip' && _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a return date & time for your round trip'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _selectedTileId = tileId;
      _selectedPaymentMethod = method;
    });
    _processPayment();
  }

  Widget _emiIcon(BuildContext context) => Container(
    width: context.w(34), height: context.w(34),
    decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(context.r(8))),
    child: Icon(Icons.calendar_month_rounded, size: context.w(20), color: const Color(0xFFF59E0B)),
  );

  Widget _googlePayTile(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(14)),
        onTap: _isProcessing ? null : _payWithGooglePay,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(14)),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.r(14)), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(children: [
            const CheckoutIcon('assets/NewIcons/gpay.png'),
            SizedBox(width: context.w(12)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Google Pay', style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              SizedBox(height: context.h(2)),
              Text('Pay instantly from the Google Pay app', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.fs(12), color: AppColors.subhead)),
            ])),
            SizedBox(width: context.w(8)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(7)),
              decoration: BoxDecoration(color: AppColors.AppBlue, borderRadius: BorderRadius.circular(context.r(8))),
              child: Text('PAY', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _errorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xffFEF2F2),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: const Color(0xffFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: context.w(16), color: const Color(0xffB42318)),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(message, style: TextStyle(color: const Color(0xffB42318), fontSize: context.fs(12))),
          ),
        ],
      ),
    );
  }

  // ==================== STATUS ====================
  Widget _processingCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(48)),
      child: AppLoadingView(message: _statusMessage),
    );
  }

  /// Pays from the wallet: /wallet/pay-booking/ debits it (same as the
  /// website), then the reservation is created against that debit.
  Future<void> _payWithWallet() async {
    // Wallet payment requires a logged-in user.
    if (!di.sl<PreferencesManager>().isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to pay with your wallet'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_walletDebitRef != null) {
      setState(() => _errorMessage =
          'Your wallet has already been charged for this booking (ref '
          '$_walletDebitRef). Please contact support — do not pay again.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = 'Checking your wallet balance...';
    });
    try {
      final response = await di.sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;

      if (balance >= widget.totalAmount) {
        if (!await _debitWallet()) return;
        setState(() => _statusMessage = 'Confirming your booking...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment successful from wallet!'),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Wallet paid → record the booking via the reservation API.
        await _createReservation(
          gateway: 'wallet',
          paymentReferenceId: _walletDebitRef!,
        );
        if (mounted) setState(() => _isProcessing = false);
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient wallet balance '
              '(INR ${balance.toStringAsFixed(2)} available)',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch wallet balance. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Charges the wallet for this booking against [_orderReferenceId].
  /// Returns false, with the reason shown, if it wasn't charged.
  Future<bool> _debitWallet() async {
    setState(() => _statusMessage = 'Paying from your wallet...');
    final debit = await di.sl<WalletApiService>().payBooking(
      amount: double.parse(widget.totalAmount.toStringAsFixed(2)),
      bookingType: 'transport',
      bookingRef: _orderReferenceId,
      description: 'Transport: ${widget.vehicleName} from '
          '${widget.pickupLocation} to ${widget.dropoffLocation}',
    );
    if (!mounted) return false;
    if (debit.success) {
      _walletDebitRef = debit.reference ?? _orderReferenceId;
      return true;
    }
    setState(() {
      _isProcessing = false;
      _errorMessage = debit.error ?? 'Wallet payment failed. Please try again.';
    });
    return false;
  }

  // ============================================================
  // ----- Razorpay Custom Checkout (same native Android SDK bridge as
  // AkFlightPaymentScreen) -----
  // ============================================================
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a payment method'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_tripType == 'round_trip' && _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a return date & time for your round trip'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Wallet uses the wallet-balance flow; every Custom Checkout method
    // (card/UPI/netbanking/wallet provider) is launched straight from its
    // own tile — see _startCardCheckout() etc. below.
    if (_selectedPaymentMethod == 'wallet') {
      await _payWithWallet();
    }
  }

  /// The Razorpay order's reference_id, so a payment can be matched back to
  /// this booking attempt — deterministic per search+result so retries
  /// reuse the same reference instead of a fresh timestamp each time.
  String get _orderReferenceId {
    final raw = 'transport_${widget.searchId}_${widget.resultId}';
    final sanitized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_');
    return sanitized.length > 40 ? sanitized.substring(0, 40) : sanitized;
  }

  /// Creates the Razorpay order the first time the customer taps ANY Custom
  /// Checkout method, and reuses it afterwards — an order must be created
  /// exactly once per payment attempt, so switching between method screens
  /// (e.g. Card → back → UPI) must never create a second one.
  Future<bool> _ensureRazorpayOrder() async {
    if (_razorpayOrderId != null && _razorpayKeyId != null) return true;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Preparing payment...';
    });

    try {
      // Total is shown in INR on this screen; send a 2-decimal amount.
      final amount = double.parse(widget.totalAmount.toStringAsFixed(2));
      final dio = di.sl<DioClient>().instance;
      final userId = di.sl<PreferencesManager>().getUserId();
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': amount,
          'currency': 'INR',
          'reference_id': _orderReferenceId,
          // Same as the website: tells the backend (webhook reconciliation)
          // what this payment is for.
          'transaction_type': 'transport',
          if (userId != null) 'user_id': userId,
        },
      );

      final orderId = response.data['order_id'] as String?;
      final keyId = response.data['key_id'] as String?;

      if (!mounted) return false;

      if (orderId == null || keyId == null) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not create payment order. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }

      setState(() {
        _isProcessing = false;
        _razorpayOrderId = orderId;
        _razorpayKeyId = keyId;
      });
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      setState(() => _isProcessing = false);
      print('Razorpay order error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create payment order. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _isProcessing = false);
      print('Razorpay checkout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start payment. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

  Future<Map<String, dynamic>> _loadMethods() {
    return _methods ??= () async {
      if (!await _ensureRazorpayOrder()) throw Exception('order');
      return _rzService.getPaymentMethods(keyId: _razorpayKeyId!);
    }().catchError((Object e) { _methods = null; throw e; });
  }

  Future<void> _payWithMethod(Map<String, dynamic> method) async {
    if (_isProcessing) return;
    FocusScope.of(context).unfocus();

    final ready = await _ensureRazorpayOrder();
    if (!ready || !mounted) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Complete the payment to continue...';
    });

    try {
      final result = await _rzService.submitPayment(
        keyId: _razorpayKeyId!,
        data: {
          'amount': (widget.totalAmount * 100).round(),
          'currency': 'INR',
          'order_id': _razorpayOrderId,
          'email': widget.passengerEmail,
          'contact': widget.passengerPhone,
          'description': 'Transport: ${widget.vehicleName}',
          ...method,
        },
      );
      await _verifyAndConfirmBooking(
        paymentId: result.paymentId,
        orderId: result.orderId,
        signature: result.signature,
      );
    } on RazorpayCustomCheckoutException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('cancel')) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled. You can try again.'), behavior: SnackBarBehavior.floating));
      } else {
        if (mounted) setState(() {
          _isProcessing = false;
          _errorMessage = e.message;
        });
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _payWithGooglePay() async {
    if (_isProcessing) return;
    final apps = await _upiApps;
    final gpay = apps.where((a) => a.isGooglePay).firstOrNull;
    if (!mounted) return;
    if (gpay == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Google Pay isn't installed. Try another method."),
        behavior: SnackBarBehavior.floating));
      setState(() => _open = 'upi');
      return;
    }
    await _payWithMethod({'method': 'upi', '_[flow]': 'intent', 'upi_app_package_name': gpay.package});
  }

  /// Verifies the signature server-side, then records the booking via the
  /// reservation API — same contract [_createReservation] already uses for
  /// the wallet path.
  Future<void> _verifyAndConfirmBooking({
    required String? paymentId,
    required String? orderId,
    required String? signature,
  }) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying payment...';
    });

    try {
      final dio = di.sl<DioClient>().instance;
      final verifyResponse = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'reference_id': _orderReferenceId,
        },
      );

      if (!mounted) return;

      if (verifyResponse.data['success'] == true) {
        setState(() => _statusMessage = 'Confirming your booking...');
        await _createReservation(
          gateway: 'razorpay',
          paymentReferenceId: _orderReferenceId,
          razorpayOrderId: orderId ?? '',
          razorpayPaymentId: paymentId ?? '',
        );
        if (mounted) setState(() => _isProcessing = false);
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification failed. Please contact support.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      print('Razorpay verify error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not verify payment. Please contact support.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$dayName, $monthName $day, $year, $hour:$minute';
  }
}
