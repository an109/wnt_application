import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/constants/urls.dart';
import 'package:wander_nova/core/network/dio_client.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import '../../../../core/error/data_state.dart';
import '../../../AKHotelRetrieveBooking/domain/entity/AKHotelRetrieveBooking_entity.dart';
import '../../../AKHotelRetrieveBooking/domain/usecase/AKHotelRetrieveBooking_usecase.dart';
import '../../../AKHotelStartPay/domain/entity/AKHotelStartPay_entity.dart';
import '../../../AKHotelStartPay/domain/usecase/AKHotelStartPay_usecase.dart';
import '../../../flight_payment/data/razorpay_custom_checkout_service.dart';
import '../../../wallet/data/data_source/wallet_api_service.dart';
import '../../../wallet/wallet/screen/checkout/card_form.dart';
import '../../../wallet/wallet/screen/checkout/checkout_ui.dart';
import '../../../wallet/wallet/screen/checkout/method_sections.dart';
import '../../../wallet/wallet/screen/checkout/upi_section.dart';
import 'ak_hotel_booking_confirmed_screen.dart';

/// Payment step for the Akbar Hotels flow: this app's own gateway (Razorpay
/// or wallet), NOT an Akbar call — exactly like the flight flow. The
/// payment reference recorded here is handed to StartPay, which looks it up
/// and refuses to book without a settled transaction against it. StartPay
/// is the only irreversible call in the whole chain, so it's called once
/// (not retried blindly) — a timeout is resolved by reading the truth back
/// via RetrieveBooking, not by calling StartPay again.
///
/// UI mirrors [AkFlightPaymentScreen]'s option-card layout (one-tap rows, no
/// separate "Pay Now" button) — Wallet uses the wallet-balance flow, and
/// every Razorpay Custom Checkout method (card/UPI/netbanking/wallet
/// provider) opens its own checkout screen directly, same native Android
/// SDK bridge [AkFlightPaymentScreen] uses. EMI and Pay Later stay static
/// placeholders — EMI has no checkout screen of its own yet, and Pay Later
/// needs separate Razorpay account approval.
class AkHotelPaymentScreen extends StatefulWidget {
  final String transactionId;
  final double netAmount;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  final String searchTracingKey;

  /// Optional display-only extras for the summary card — all real data
  /// threaded from [AkHotelPriceConfirmScreen] when available; every one
  /// defaults to empty so a caller that doesn't have them yet just gets a
  /// slightly plainer card instead of a fabricated placeholder.
  final String hotelImage;
  final String checkInTime;
  final String checkOutTime;
  final String guestsSummary;

  /// Everything below is threaded straight through to
  /// [AkHotelBookingConfirmedScreen] once payment succeeds — carried here
  /// only because that's the one place this data (hotel Content, priced
  /// room, lead guest) is still in scope. Never displayed on this screen.
  final String hotelAddress;
  final String hotelCity;
  final String hotelCountry;
  final int starRating;
  final double reviewRating;
  final String roomType;
  final String mealPlan;
  final int roomsCount;
  final int adultsCount;
  final int childrenCount;
  final double baseFare;
  final String leadGuestName;
  final String leadGuestEmail;
  final String leadGuestPhone;

  const AkHotelPaymentScreen({
    super.key,
    required this.transactionId,
    required this.netAmount,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.searchTracingKey,
    this.hotelImage = '',
    this.checkInTime = '',
    this.checkOutTime = '',
    this.guestsSummary = '',
    this.hotelAddress = '',
    this.hotelCity = '',
    this.hotelCountry = '',
    this.starRating = 0,
    this.reviewRating = 0,
    this.roomType = '',
    this.mealPlan = '',
    this.roomsCount = 1,
    this.adultsCount = 1,
    this.childrenCount = 0,
    this.baseFare = 0,
    this.leadGuestName = '',
    this.leadGuestEmail = '',
    this.leadGuestPhone = '',
  });

  @override
  State<AkHotelPaymentScreen> createState() => _AkHotelPaymentScreenState();
}

class _AkHotelPaymentScreenState extends State<AkHotelPaymentScreen> {
  static const _pri = AppColors.AppBlue;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);
  static const _offer = Color(0xFF16A34A);

  bool _processing = false;
  String _statusMessage = '';
  String? _errorMessage;
  String? _selectedPaymentMethod;

  // Only the tapped card shows the brief selected highlight.
  String? _selectedTileId;

  // ---- Razorpay Custom Checkout (native Android SDK bridge, same as
  // AkFlightPaymentScreen) ----
  /// Set once the first Custom Checkout attempt creates an order, then
  /// reused by every method screen — an order must be created exactly once
  /// per payment attempt.
  String? _razorpayOrderId;
  String? _razorpayKeyId;

  // Set once /wallet/pay-booking/ has charged the wallet for this booking —
  // StartPay is never re-run blindly, and the wallet is never charged twice.
  String? _walletDebitRef;

  // Inline accordion payment sections
  String? _open;
  final _rzService = RazorpayCustomCheckoutService();
  late final Future<List<UpiApp>> _upiApps = _rzService.getUpiApps().catchError((_) => <UpiApp>[]);
  Future<Map<String, dynamic>>? _methods;

  /// Checkout hold — same 15-minute UI guard [AkFlightPaymentScreen] uses.
  /// Purely local: it never cancels anything itself, just stops the
  /// traveller paying against a session that has likely gone stale.
  static const _holdDuration = Duration(minutes: 15);
  Timer? _holdTimer;
  Duration _timeLeft = _holdDuration;
  bool get _expired => _timeLeft <= Duration.zero;
  String get _minutes => _timeLeft.inMinutes.toString().padLeft(2, '0');
  String get _seconds => (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = _timeLeft - const Duration(seconds: 1);
      setState(() => _timeLeft = next.isNegative ? Duration.zero : next);
      if (_timeLeft <= Duration.zero) timer.cancel();
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() => _errorMessage = 'Please select a payment method');
      return;
    }
    // Wallet uses the wallet-balance flow; every Custom Checkout method
    // (card/UPI/netbanking/wallet provider) is launched straight from its
    // own tile — see _startCardCheckout() etc. below.
    if (_selectedPaymentMethod == 'wallet') {
      await _payWithWallet();
    }
  }

  /// Pays from the wallet: /wallet/pay-booking/ debits it against the
  /// itinerary TransactionID (what StartPay's payment guard looks for, same
  /// as the website), then StartPay runs with gateway 'wallet'.
  Future<void> _payWithWallet() async {
    if (_walletDebitRef != null) {
      setState(() => _errorMessage =
          'Your wallet has already been charged for this booking. Please '
          'contact support with Transaction ID ${widget.transactionId} — do not pay again.');
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = null;
      _statusMessage = 'Checking wallet balance...';
    });

    try {
      final response = await sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;

      if (balance >= widget.netAmount) {
        if (await _debitWallet()) {
          await _runStartPay(gateway: 'wallet', paymentReference: widget.transactionId);
        }
      } else {
        setState(() {
          _processing = false;
          _errorMessage = 'Insufficient wallet balance (₹${balance.toStringAsFixed(2)} available)';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not fetch wallet balance. Please try again.';
      });
      print('Hotel wallet balance error: $e');
    }
  }

  /// Charges the wallet for this booking (whole rupees, rounded up, as the
  /// website does). Returns false, with the reason shown, if it wasn't charged.
  Future<bool> _debitWallet() async {
    setState(() => _statusMessage = 'Paying from your wallet...');
    final debit = await sl<WalletApiService>().payBooking(
      amount: widget.netAmount.ceilToDouble(),
      bookingType: 'hotel',
      bookingRef: widget.transactionId,
      description: 'Hotel: ${widget.hotelName}',
    );
    if (!mounted) return false;
    if (debit.success) {
      _walletDebitRef = debit.reference ?? widget.transactionId;
      return true;
    }
    setState(() {
      _processing = false;
      _errorMessage = debit.error ?? 'Wallet payment failed. Please try again.';
    });
    return false;
  }

  /// Creates the Razorpay order the first time the customer taps ANY Custom
  /// Checkout method, and reuses it afterwards — an order must be created
  /// exactly once per payment attempt, so switching between method screens
  /// (e.g. Card → back → UPI) must never create a second one. reference_id
  /// equals the itinerary TransactionID so hotel StartPay's payment guard
  /// can look up this exact paid transaction, same as before.
  Future<bool> _ensureRazorpayOrder() async {
    if (_razorpayOrderId != null && _razorpayKeyId != null) return true;

    setState(() {
      _processing = true;
      _errorMessage = null;
      _statusMessage = 'Preparing payment...';
    });

    try {
      final dio = sl<DioClient>().instance;
      final userId = sl<PreferencesManager>().getUserId();
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': widget.netAmount,
          'currency': 'INR',
          'reference_id': widget.transactionId,
          // Same as the website: tells the backend (webhook reconciliation)
          // what this payment is for.
          'transaction_type': 'hotel',
          if (userId != null) 'user_id': userId,
        },
      );

      final orderId = response.data['order_id'] as String?;
      final keyId = response.data['key_id'] as String?;

      if (!mounted) return false;

      if (orderId == null || keyId == null) {
        setState(() {
          _processing = false;
          _errorMessage = 'Could not create payment order. Please try again.';
        });
        return false;
      }

      setState(() {
        _processing = false;
        _razorpayOrderId = orderId;
        _razorpayKeyId = keyId;
      });
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not create payment order. Please try again.';
      });
      print('Hotel Razorpay order error: ${e.message}');
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not start payment: $e';
      });
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
    if (_expired || _processing) return;
    FocusScope.of(context).unfocus();

    final ready = await _ensureRazorpayOrder();
    if (!ready || !mounted) return;

    setState(() {
      _processing = true;
      _statusMessage = 'Complete the payment to continue...';
      _errorMessage = null;
    });

    try {
      final result = await _rzService.submitPayment(
        keyId: _razorpayKeyId!,
        data: {
          'amount': (widget.netAmount * 100).round(),
          'currency': 'INR',
          'order_id': _razorpayOrderId,
          'email': widget.leadGuestEmail,
          'contact': widget.leadGuestPhone,
          'description': 'Hotel booking: ${widget.hotelName}',
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
          _processing = false;
          _errorMessage = e.message;
        });
      }
    }
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _payWithGooglePay() async {
    if (_expired || _processing) return;
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

  /// Verifies the signature server-side, then continues exactly as before —
  /// StartPay with paymentReference == the itinerary TransactionID (not the
  /// raw Razorpay payment id — StartPay's guard looks up by reference_id).
  Future<void> _verifyAndConfirmBooking({
    required String? paymentId,
    required String? orderId,
    required String? signature,
  }) async {
    setState(() {
      _processing = true;
      _statusMessage = 'Verifying payment...';
      _errorMessage = null;
    });

    try {
      final dio = sl<DioClient>().instance;
      final verifyResponse = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'reference_id': widget.transactionId,
        },
      );

      if (!mounted) return;

      if (verifyResponse.data['success'] == true) {
        await _runStartPay(gateway: 'razorpay', paymentReference: widget.transactionId);
      } else {
        setState(() {
          _processing = false;
          _errorMessage = 'Payment verification failed. Please contact support.';
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not verify payment. Please contact support.';
      });
      print('Hotel Razorpay verify error: ${e.message}');
    }
  }

  Future<void> _runStartPay({required String gateway, required String paymentReference}) async {
    setState(() {
      _processing = true;
      _statusMessage = 'Confirming your booking...';
    });

    final result = await sl<AkHotelStartPayUseCase>().call(
      AkHotelStartPayRequestEntity(
        transactionId: widget.transactionId,
        netAmount: widget.netAmount,
        paymentAmount: widget.netAmount,
        paymentReference: paymentReference,
        gateway: gateway,
        searchTracingKey: widget.searchTracingKey,
      ),
    );

    if (!mounted) return;

    if (result is DataSuccess<AkHotelStartPayEntity> && result.data!.isBooked) {
      await _retrieveBookingAndNavigate(result.data!, gateway);
      return;
    }

    // Payment has already been captured by this point (Razorpay charged, or
    // wallet balance treated as debited) — StartPay refusing here does NOT
    // mean the customer wasn't charged, so the message always carries the
    // Transaction ID they'll need for support to reconcile it.
    final reason = result is DataFailed<AkHotelStartPayEntity>
        ? (result.error?.message ?? 'booking confirmation failed')
        : 'booking confirmation failed';
    setState(() {
      _processing = false;
      _errorMessage =
          'Payment received, but the booking could not be confirmed yet ($reason). '
          'Please contact support with Transaction ID ${widget.transactionId} — do not pay again.';
    });
  }

  /// RetrieveBooking is read-only and safe to call any time — used here to
  /// enrich the confirmation screen, not to decide success (StartPay's own
  /// isBooked already did that).
  Future<void> _retrieveBookingAndNavigate(AkHotelStartPayEntity startPay, String gateway) async {
    final result = await sl<AkHotelRetrieveBookingUseCase>().call(
      AkHotelRetrieveBookingRequestEntity(referenceNumber: widget.transactionId),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AkHotelBookingConfirmedScreen(
          hotelName: widget.hotelName,
          transactionId: widget.transactionId,
          crsPnr: startPay.crsPnr,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          checkInTime: widget.checkInTime,
          checkOutTime: widget.checkOutTime,
          hotelImage: widget.hotelImage,
          hotelAddress: widget.hotelAddress,
          hotelCity: widget.hotelCity,
          hotelCountry: widget.hotelCountry,
          starRating: widget.starRating,
          reviewRating: widget.reviewRating,
          roomType: widget.roomType,
          mealPlan: widget.mealPlan,
          roomsCount: widget.roomsCount,
          adultsCount: widget.adultsCount,
          childrenCount: widget.childrenCount,
          baseFare: widget.baseFare,
          netAmount: widget.netAmount,
          leadGuestName: widget.leadGuestName,
          leadGuestEmail: widget.leadGuestEmail,
          leadGuestPhone: widget.leadGuestPhone,
          paymentGateway: gateway,
          bookedAt: DateTime.now(),
          booking: result is DataSuccess<AkHotelRetrieveBookingEntity> ? result.data : null,
        ),
      ),
    );
  }

  /// One-tap: remember the method for [_processPayment]'s existing routing,
  /// then start it straight away — same interaction [AkFlightPaymentScreen]
  /// uses, no separate "Pay Now" button.
  void _payWith(String method, String tileId) {
    if (_expired || _processing) return;
    setState(() {
      _selectedTileId = tileId;
      _selectedPaymentMethod = method;
      _errorMessage = null;
    });
    _processPayment();
  }

  String _prettyDate(String mmddyyyy) {
    try {
      return DateFormat('d MMM').format(DateFormat('MM/dd/yyyy').parseStrict(mmddyyyy));
    } catch (_) {
      return mmddyyyy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Divider(height: 1, color: _stroke),
            Expanded(
              child: SingleChildScrollView(
                physics: context.scrollPhysics,
                padding: EdgeInsets.fromLTRB(context.w(16), context.h(18), context.w(16), context.h(32)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _totalDue(context),
                    SizedBox(height: context.h(16)),
                    _summaryCard(context),
                    SizedBox(height: context.h(24)),
                    if (_processing) ...[
                      _processingCard(context),
                    ] else ...[
                      if (_errorMessage != null) ...[
                        _errorBanner(context, _errorMessage!),
                        SizedBox(height: context.h(16)),
                      ],
                      if (_expired) ...[
                        _errorBanner(context, 'This payment session has timed out. Please go back and start the booking again.'),
                        SizedBox(height: context.h(16)),
                      ],
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
                      _promoStrip(context, 'Get an additional Rs 300 off with HDFCEMI on 6 month EMI.'),
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
                          amount: widget.netAmount,
                          busy: _processing,
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
                          payLabel: 'Pay ${formatInr(widget.netAmount)}',
                          busy: _processing,
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
                          amount: widget.netAmount,
                          busy: _processing,
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
                          amount: widget.netAmount,
                          busy: _processing,
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
                          amount: widget.netAmount,
                          busy: _processing,
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
      padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _processing ? null : () => Navigator.of(context).maybePop(),
            child: Icon(Icons.arrow_back_rounded, size: context.w(22), color: Colors.black),
          ),
          SizedBox(width: context.w(15)),
          Expanded(
            child: Text(
              'Payment',
              style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
          Icon(Icons.timer, size: context.w(16), color: _expired ? const Color(0xffB42318) : _pri),
          SizedBox(width: context.w(4)),
          Text(
            '$_minutes:$_seconds',
            style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: _expired ? const Color(0xffB42318) : _pri),
          ),
        ],
      ),
    );
  }

  // ==================== TOTAL DUE ====================
  Widget _totalDue(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Total Due',
            style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        SizedBox(width: context.w(8)),
        Text(
          '₹${widget.netAmount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.w800, color: Colors.black),
        ),
      ],
    );
  }

  /// Hotel + stay summary, always visible (unlike the flight screen's
  /// tap-to-reveal drawer) — matches the reference picture, which shows this
  /// card inline under Total Due rather than hidden behind a chevron.
  Widget _summaryCard(BuildContext context) {
    final when = [
      if (widget.checkIn.isNotEmpty) _prettyDate(widget.checkIn),
      if (widget.checkInTime.isNotEmpty) widget.checkInTime,
      if (widget.checkOut.isNotEmpty) '-${_prettyDate(widget.checkOut)}',
      if (widget.checkOutTime.isNotEmpty) widget.checkOutTime,
    ].join(' | ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(context.r(8)),
                child: widget.hotelImage.isEmpty
                    ? Container(
                        width: context.w(44),
                        height: context.w(44),
                        color: const Color(0xFFF1F5F9),
                        child: Icon(Icons.apartment_rounded, size: context.w(20), color: _muted),
                      )
                    : Image.network(
                        widget.hotelImage,
                        width: context.w(44),
                        height: context.w(44),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: context.w(44),
                          height: context.w(44),
                          color: const Color(0xFFF1F5F9),
                          child: Icon(Icons.apartment_rounded, size: context.w(20), color: _muted),
                        ),
                      ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hotelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(13.5), fontWeight: FontWeight.w700, color: _ink),
                    ),
                    if (when.isNotEmpty) ...[
                      SizedBox(height: context.h(3)),
                      Text(when, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: context.fs(11), color: _muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.guestsSummary.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(10)),
              child: Divider(height: 1, color: _stroke),
            ),
            Text(widget.guestsSummary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: context.fs(11.5), color: _muted)),
          ],
        ],
      ),
    );
  }

  // ==================== OPTIONS ====================
  Widget _sectionLabel(BuildContext context, String text) => Text(
        text,
        style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600, color: Colors.black),
      );

  /// A white bordered card that groups one or more [_optionRow]s. Rows
  /// inside stack with no divider between them.
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

  /// Green promo strip shown above a payment card. Purely informational.
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
            child: Text(text, style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: _ink, height: 1.35)),
          ),
        ],
      ),
    );
  }

  /// One payment option ROW — no card chrome of its own, so it can be the
  /// sole child of a card or stacked with siblings inside a shared card. One
  /// tap on an interactive row selects the method and immediately kicks off
  /// [_processPayment] — there is no separate Pay button.
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
    // Static rows render like the real ones but don't select or route.
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
              : Icon(icon, size: context.w(22), color: iconColor == Colors.transparent ? _ink : iconColor),
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
                            style: TextStyle(fontSize: context.fs(9), fontWeight: FontWeight.w800, color: tagColor, letterSpacing: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.h(3)),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: context.fs(12), color: _muted)),
              ],
            ),
          ),
          SizedBox(width: context.w(8)),
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
      onTap: (_expired || _processing)
          ? null
          : (onTapOverride ?? () => _payWith(method!, tileId)),
      child: content,
    );
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
        onTap: (_expired || _processing) ? null : _payWithGooglePay,
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

  // ==================== STATUS ====================
  Widget _processingCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(48)),
      child: Column(
        children: [
          const CircularProgressIndicator(color: _pri),
          SizedBox(height: context.h(16)),
          Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: context.fs(13))),
        ],
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
}
