import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/constants/urls.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/error/data_state.dart';
import 'package:wander_nova/core/network/dio_client.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/AKInsurance/domain/entity/AKInsurance_entity.dart';
import 'package:wander_nova/views/AKInsurance/domain/usecase/AKInsurance_usecase.dart';
import 'package:wander_nova/views/AKRetrieveBooking/domain/entity/AKRetrieveBooking_entity.dart';
import 'package:wander_nova/views/AKRetrieveBooking/domain/usecase/AKRetrieveBooking_usecase.dart';
import 'package:wander_nova/views/AKStartPay/domain/entity/AKStartPay_entity.dart';
import 'package:wander_nova/views/AKStartPay/domain/usecase/AKStartPay_usecase.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/seat_addons_screen.dart';
import 'package:wander_nova/views/flight_ticket/presentation/screen/ak_ticket_confirmation_screen.dart';
import 'package:wander_nova/views/wallet/data/data_source/wallet_api_service.dart';

/// Payment + ticketing for the Akbar flow. CreateItinerary has already
/// persisted the full booking server-side by session_id before this screen
/// runs, so — unlike the old TBO flow — there is no "prepare ticket" payload
/// to build client-side: this screen only charges the customer and then
/// tells the backend (via StartPay) to issue the ticket against that
/// session_id.
class AkFlightPaymentScreen extends StatefulWidget {
  final FlightRouteSegment route;
  final Map<String, dynamic> leadPassenger;
  final double netAmount;

  /// The return leg for RT/RS, or legs 2..N for Multi City. Empty for a
  /// plain one-way booking. Carried through to [AkTicketConfirmationScreen]
  /// so round trips can show both flights.
  final List<FlightRouteSegment> additionalLegs;

  /// Total travellers on this booking, carried through to
  /// [AkTicketConfirmationScreen] for the summary/PDF.
  final int travellerCount;

  /// Every traveller's full name (not just the lead's), carried through to
  /// [AkTicketConfirmationScreen] so the ticket can list everyone.
  final List<String> travellerNames;

  /// Full per-traveller maps (title / name / gender / paxType / dateOfBirth …),
  /// forwarded untouched to [AkTicketConfirmationScreen] so its per-passenger
  /// rows can show type, age and e-ticket number. Empty for callers that don't
  /// have them.
  final List<Map<String, dynamic>> travellers;

  /// Seats / meals / other extras chosen on [SeatAddonsScreen], forwarded to
  /// [AkTicketConfirmationScreen] for its per-passenger add-on chips.
  final AddOnsSummary addOns;

  /// Non-null only when the traveller picked a Trip Secure plan AND passed
  /// its KYC on the booking screen. When present, its premium is folded
  /// into the one Razorpay/wallet charge below, and the policy is issued
  /// (ValidateKYC already done — StartPay + GetItinerary) right after the
  /// flight itself is booked. Trip Secure failing here never blocks the
  /// flight ticket (fail-soft) — the flight booking has already succeeded
  /// by the time this runs.
  final TripSecureBookingContext? insuranceBookingContext;

  const AkFlightPaymentScreen({
    super.key,
    required this.route,
    required this.leadPassenger,
    required this.netAmount,
    this.additionalLegs = const [],
    this.travellerCount = 1,
    this.travellerNames = const [],
    this.travellers = const [],
    this.addOns = const AddOnsSummary(),
    this.insuranceBookingContext,
  });

  @override
  State<AkFlightPaymentScreen> createState() => _AkFlightPaymentScreenState();
}

class _AkFlightPaymentScreenState extends State<AkFlightPaymentScreen> {
  // ---- Figma tokens (Payment — node 501:2849) ----
  static const _pri = AppColors.AppBlue; // #00A1E4
  static const _muted = AppColors.subhead; // #757575
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);
  static const _offer = Color(0xFF16A34A); // highlight-tag green

  String get _minutes => _timeLeft.inMinutes.toString().padLeft(2, '0');
  String get _seconds => (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

  // Fare top-drawer gradient — Figma "Total drop flight": #FFFFFF → #80DAFF,
  // top to bottom, across the whole drawer.
  static const _fareGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFF80DAFF)],
  );

  /// Checkout hold. Purely a UI guard: it stops the user paying against a
  /// session that has almost certainly gone stale server-side, and never
  /// cancels anything itself.
  static const _holdDuration = Duration(minutes: 15);
  Timer? _holdTimer;
  Duration _timeLeft = _holdDuration;
  bool get _expired => _timeLeft <= Duration.zero;

  late final Razorpay _razorpay;

  bool _processing = false;
  String _statusMessage = '';
  String? _errorMessage;

  // The method the last tapped card routes to: 'wallet' uses the
  // wallet-balance flow, 'razorpay' opens the Razorpay checkout. Set by
  // [_payWith] just before [_processPayment] runs.
  String? _selectedPaymentMethod;

  // The specific card the user tapped ('wallet', 'razorpay', 'gpay', …) —
  // only that card shows the brief selected highlight before payment starts.
  String? _selectedTileId;

  // Razorpay's payment id — the real gateway transaction reference, shown on
  // the confirmation screen. Null for wallet payments (no gateway involved).
  String? _transactionId;

  static const _maxStartPayAttempts = 6;
  static const _defaultRetryDelaySeconds = 5;

  String get _sessionId => widget.route.sessionId ?? '';

  /// Akbar amounts (netAmount, wallet balance) are always in INR — this
  /// converts to whatever currency the user has picked in Settings, instead
  /// of always showing a hardcoded ₹.
  String _displayAmount(double amountInInr) {
    final prefs = sl<PreferencesManager>();
    final target = prefs.getPreferredCurrency() ?? 'INR';
    final converted = target.toUpperCase() == 'INR'
        ? amountInInr
        : CurrencyConverter.convert(amount: amountInInr, fromCurrency: 'INR', toCurrency: target);
    return CurrencyConverter.format(converted, target);
  }

  /// The Trip Secure premium, in raw INR — never the user's display currency.
  /// [AkInsuranceQuotesModel] defaults a missing currency to 'INR' already,
  /// so the conversion below is normally a no-op; it only does real work if a
  /// provider ever quotes in something else.
  double get _insurancePremiumInInr {
    final insurance = widget.insuranceBookingContext;
    if (insurance == null) return 0;
    final premium = insurance.plan.premium;
    final currency = insurance.plan.currency;
    return currency.toUpperCase() == 'INR'
        ? premium
        : CurrencyConverter.convert(amount: premium, fromCurrency: currency, toCurrency: 'INR');
  }

  /// What is actually charged to the customer's card/wallet: flight net
  /// amount plus Trip Secure's premium when one was selected, combined into
  /// the single Razorpay/wallet charge below.
  ///
  /// UNVERIFIED ASSUMPTION: flight StartPay is keyed only by session_id/
  /// gateway (no amount field), so it's unclear whether the backend also
  /// checks the *paid* Razorpay amount against CreateItinerary's own
  /// netAmount before confirming the flight. If it does, inflating the order
  /// total here to include the insurance premium could make that check fail.
  /// This has not been (and per the API notes, cannot safely be) live-tested
  /// — confirm server-side before relying on it in production.
  double get _totalChargeInInr => widget.netAmount + _insurancePremiumInInr;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);

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
    _razorpay.clear();
    super.dispose();
  }

  /// Routes payment to the flow matching [_selectedPaymentMethod]:
  ///   wallet    → wallet-balance check then StartPay directly
  ///   razorpay  → Razorpay native checkout
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() => _errorMessage = 'Please select a payment method');
      return;
    }
    if (_selectedPaymentMethod == 'wallet') {
      await _payWithWallet();
      return;
    }
    await _initiatePayment();
  }

  /// Pays from the wallet if its balance covers the total. There is no debit
  /// endpoint (same limitation as the TBO flow's wallet option), so a
  /// sufficient balance is treated as payment received and StartPay is
  /// called directly with gateway 'wallet'.
  Future<void> _payWithWallet() async {
    final prefs = sl<PreferencesManager>();
    if (!prefs.isLoggedIn()) {
      setState(() => _errorMessage = 'Please log in to pay with your wallet');
      return;
    }
    if (_sessionId.isEmpty) {
      setState(() => _errorMessage = 'Booking session expired. Please start over.');
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

      if (balance >= _totalChargeInInr) {
        await _runStartPayWithRetry(gateway: 'wallet');
      } else {
        setState(() {
          _processing = false;
          _errorMessage = 'Insufficient wallet balance (${_displayAmount(balance)} available)';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not fetch wallet balance. Please try again.';
      });
      print('Wallet balance error: $e');
    }
  }

  Future<void> _initiatePayment() async {
    if (_sessionId.isEmpty) {
      setState(() => _errorMessage = 'Booking session expired. Please start over.');
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = null;
      _statusMessage = 'Opening secure payment...';
    });

    try {
      final dio = sl<DioClient>().instance;
      // reference_id must equal session_id so StartPay's payment guard can
      // match the paid transaction to this booking session.
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': _totalChargeInInr,
          'currency': 'INR',
          'reference_id': _sanitizedOrderId(_sessionId),
        },
      );

      final orderId = response.data['order_id'] as String?;
      final keyId = response.data['key_id'] as String?;
      print("Razorpay Key: $keyId");

      if (!mounted) return;
      setState(() => _processing = false);

      final firstName = (widget.leadPassenger['firstName'] ?? '').toString();
      final lastName = (widget.leadPassenger['lastName'] ?? '').toString();
      final email = (widget.leadPassenger['email'] ?? '').toString();
      final phone = (widget.leadPassenger['mobileNumber'] ?? '').toString();

      _razorpay.open({
        'key': keyId ?? '',
        'amount': (_totalChargeInInr * 100).toInt(),
        'currency': 'INR',
        'name': 'WanderNova',
        'description': 'Flight ${widget.route.from} → ${widget.route.to}',
        'order_id': orderId ?? '',
        'prefill': {
          'name': '$firstName $lastName'.trim(),
          'email': email,
          'contact': phone,
        },
        'theme': {'color': '#1769F6'},
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not create payment order. Please try again.';
      });
      print('Razorpay order error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
          _errorMessage = 'Could not start payment: $e';
      });
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() {
      _processing = true;
      _statusMessage = 'Verifying payment...';
      _errorMessage = null;
      _transactionId = response.paymentId;
    });

    try {
      final dio = sl<DioClient>().instance;
      final verifyResponse = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'reference_id': _sanitizedOrderId(_sessionId),
        },
      );

      if (!mounted) return;

      if (verifyResponse.data['success'] == true) {
        await _runStartPayWithRetry();
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
      print('Razorpay verify error: ${e.message}');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _errorMessage = 'Payment failed: ${response.message ?? 'Please try again.'}';
    });
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    print('Razorpay external wallet: ${response.walletName}');
  }

  /// The Razorpay order's reference_id must equal the Akbar session_id so
  /// the backend can match the paid transaction to the booking session
  /// (StartPay's payment guard requires a paid transaction with
  /// reference_id == session_id) — session_id is already a UUID, so this
  /// just guards against unexpected characters/length rather than doing
  /// real work.
  String _sanitizedOrderId(String sessionId) {
    final sanitized = sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
    return sanitized.length > 40 ? sanitized.substring(0, 40) : sanitized;
  }

  Future<void> _runStartPayWithRetry({String gateway = 'razorpay'}) async {
    setState(() {
      _processing = true;
      _statusMessage = 'Confirming your booking...';
    });

    int attempt = 0;
    while (attempt < _maxStartPayAttempts) {
      final result = await sl<AkStartPayUseCase>().call(
        // The doc's own example gateway value is "nomod" (a different
        // gateway than what this app charges through); 'razorpay'/'wallet'
        // are the reasonable values for the respective funding method but
        // are unverified against the real backend — flagged for manual
        // confirmation.
        AkStartPayRequestEntity(sessionId: _sessionId, gateway: gateway),
      );

      if (result is DataSuccess<AkStartPayEntity>) {
        final data = result.data!;
        if (data.isBooked) {
          await _retrieveBookingAndNavigate();
          return;
        }
        if (data.bookingInProgress) {
          attempt++;
          if (!mounted) return;
          setState(() {
            _statusMessage = 'Still confirming your booking… ($attempt/$_maxStartPayAttempts)';
          });
          await Future.delayed(
            Duration(seconds: data.retryAfterSeconds ?? _defaultRetryDelaySeconds),
          );
          continue;
        }
        // Hard failure — StartPay answered but not booked and not "in progress".
        break;
      } else {
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _processing = false;
      _errorMessage = attempt >= _maxStartPayAttempts
          ? 'Your booking is still being confirmed. Please check My Bookings shortly.'
          : 'Payment succeeded but ticketing failed. Please contact support with your booking reference.';
    });
  }

  Future<void> _retrieveBookingAndNavigate() async {
    final result = await sl<AkRetrieveBookingUseCase>().call(
      AkRetrieveBookingRequestEntity(sessionId: _sessionId),
    );

    if (!mounted) return;

    if (result is DataSuccess<AkRetrieveBookingEntity>) {
      final insurance = widget.insuranceBookingContext;
      if (insurance != null) {
        setState(() => _statusMessage = 'Issuing your Trip Secure policy...');
        final issued = await _issueTripSecurePolicy(insurance);
        if (!mounted) return;
        setState(() {
          _statusMessage = issued
              ? 'Trip Secure policy issued!'
              : 'Flight booked — Trip Secure could not be issued. Contact support if needed.';
        });
        // Long enough to read, short enough not to feel stuck — the flight
        // ticket itself is already secured regardless of this outcome.
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AkTicketConfirmationScreen(
            booking: result.data!,
            route: widget.route,
            additionalLegs: widget.additionalLegs,
            leadPassenger: widget.leadPassenger,
            travellers: widget.travellers,
            addOns: widget.addOns,
            transactionId: _transactionId,
            netAmount: widget.netAmount,
            travellerCount: widget.travellerCount,
            travellerNames: widget.travellerNames,
          ),
        ),
      );
    } else {
      setState(() {
        _processing = false;
        _errorMessage =
        'Your booking is confirmed, but we could not load the ticket details. Please check My Bookings.';
      });
    }
  }

  /// Steps 6/7 + 7/7 for Trip Secure — StartPay then GetItinerary — run once
  /// the flight itself is already booked. [paymentReference] reuses the same
  /// gateway transaction the customer was actually charged under, so the
  /// premium collected above and the policy issued here reconcile to one
  /// payment. Fail-soft: any failure here just returns false, it never
  /// throws or blocks the flight ticket.
  Future<bool> _issueTripSecurePolicy(TripSecureBookingContext insurance) async {
    // Insurance StartPay has no gateway field of its own — OnlinePayment:false
    // + DepositPayment:true (below) tells the provider to settle against
    // WanderNova's own agent balance rather than expecting a customer-facing
    // charge through it directly; the actual customer charge already
    // happened via the Razorpay/wallet flow above.
    final paymentReference = _transactionId ?? _sanitizedOrderId(_sessionId);

    final leadTitle = (widget.leadPassenger['title'] ?? 'Mr').toString();
    final leadFirstName = (widget.leadPassenger['firstName'] ?? '').toString();
    final leadLastName = (widget.leadPassenger['lastName'] ?? '').toString();
    final leadPhone = (widget.leadPassenger['mobileNumber'] ?? '').toString();
    final leadEmail = (widget.leadPassenger['email'] ?? '').toString();

    final travellers = insurance.quotesRequest.travellers;
    final request = AkInsuranceStartPayRequestEntity(
      paymentReference: paymentReference,
      panNo: insurance.kyc.pan,
      countryCodes: insurance.quotesRequest.countryCodes,
      countryNames: insurance.quotesRequest.countryNames,
      startDate: insurance.quotesRequest.startDate,
      endDate: insurance.quotesRequest.endDate,
      policyType: insurance.quotesRequest.policyType,
      customer: AkInsuranceCustomerEntity(
        title: leadTitle,
        firstName: leadFirstName,
        lastName: leadLastName,
        birthDate: insurance.kyc.dob,
        contactInfo: AkInsuranceContactInfoEntity(
          number: leadPhone,
          code: '+91',
          emailAddress: leadEmail,
        ),
        // The traveller form doesn't collect an address today — same "NA"
        // placeholder flight CreateItinerary already uses for this gap.
        addresses: const [AkInsuranceAddressEntity(line1: 'NA', pinCode: '000000')],
      ),
      plans: [
        AkInsurancePlanBookingEntity(
          id: insurance.plan.planId,
          type: insurance.quotesRequest.policyType,
          travellers: [
            // Traveller ids line up with widget.travellerNames by position
            // (both are built off the same traveller-form order) — unverified
            // against the provider's own expectations for co-traveller names.
            for (final t in travellers)
              AkInsuranceBookingTravellerEntity(
                id: t.id,
                firstName: t.id < widget.travellerNames.length && widget.travellerNames[t.id].isNotEmpty
                    ? widget.travellerNames[t.id]
                    : (t.id == 0 ? '$leadFirstName $leadLastName'.trim() : 'Traveller ${t.id + 1}'),
                relationship: t.relation,
                isProposer: t.id == 0,
              ),
          ],
        ),
      ],
      // Raw INR premium — see _insurancePremiumInInr; never the display-
      // converted figure shown in the UI.
      amount: _insurancePremiumInInr.toInt(),
      onlinePayment: false,
      depositPayment: true,
      channelId: insurance.quotesRequest.channelId,
      tui: insurance.tui,
    );

    const maxAttempts = 3;
    const retryDelay = Duration(seconds: 4);
    var attempt = 0;

    while (attempt < maxAttempts) {
      final result = await sl<AkInsuranceStartPayUseCase>().call(request);
      if (result is! DataSuccess<AkInsuranceStartPayEntity>) return false;

      final data = result.data!;
      if (data.isBooked) {
        // Best-effort confirmation fetch — the policy is already issued
        // either way, so a failure here doesn't flip the outcome to false.
        await sl<AkInsuranceGetItineraryUseCase>().call(
          AkInsuranceItineraryRequestEntity(tui: insurance.tui, transactionId: data.transactionId),
        );
        return true;
      }
      if (data.bookingInProgress) {
        attempt++;
        await Future.delayed(retryDelay);
        continue;
      }
      return false;
    }
    return false;
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
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(18), context.w(16), context.h(32)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _totalDue(context),
                    SizedBox(height: context.h(24)),
                    if (_processing) ...[
                      _processingCard(context),
                    ] else ...[
                      if (_errorMessage != null) ...[
                        _errorBanner(context, _errorMessage!),
                        SizedBox(height: context.h(16)),
                      ],
                      if (_expired) ...[
                        _errorBanner(
                          context,
                          'This payment session has timed out. Please go back and start the booking again.',
                        ),
                        SizedBox(height: context.h(16)),
                      ],
                      _sectionLabel(context, 'Suggested options'),
                      SizedBox(height: context.h(12)),
                      // Wallet + Razorpay — kept exactly as-is, each its own
                      // card. One tap starts payment straight away.
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
                      _optionCard(context, children: [
                        _optionRow(
                          context,
                          tileId: 'razorpay',
                          method: 'razorpay',
                          icon: Icons.payment_rounded,
                          iconColor: const Color(0xFF2F80ED),
                          iconBg: const Color(0xFFEFF6FF),
                          title: 'Razorpay',
                          subtitle: 'Cards, UPI, Net Banking, Wallets',
                        ),
                      ]),
                      _promoStrip(context, 'Get extra discount on UPI of Rs 32'),
                      // GooglePay + UPI Options — one card, no divider between.
                      _optionCard(context, children: [
                        _optionRow(
                          context,
                          tileId: 'gpay',
                          method: 'razorpay',
                          // icon: Icons.g_mobiledata_rounded,
                          iconAsset: 'assets/NewIcons/gpay.png',
                          iconColor: const Color(0xFF4285F4),
                          iconBg: const Color(0xFFEFF6FF),
                          title: 'GooglePay',
                          subtitle: 'Pay with GooglePay',
                        ),
                        _optionRow(
                          context,
                          tileId: 'upi',
                          method: 'razorpay',
                          // icon: Icons.qr_code_2_rounded,
                          iconAsset: 'assets/NewIcons/upi.png',
                          // iconColor: const Color(0xFF5F259F),
                          iconBg: const Color(0xFFF3E8FF),
                          title: 'UPI Options',
                          subtitle: 'Pay Directly From Your Bank Account',
                        ),
                      ]),
                      SizedBox(height: context.h(12)),
                      _sectionLabel(context, 'Other Payment Options'),
                      SizedBox(height: context.h(12)),
                      // Static for now — render like the real cards but don't
                      // select or route anything. Payment handling is added
                      // later. Credit & Debit is its own card; Net Banking /
                      // Pay Later / Gift Cards share one card, no dividers.
                      _optionCard(context, children: [
                        _optionRow(
                          context,
                          tileId: 'card',
                          interactive: false,
                          iconAsset: 'assets/NewIcons/credit.png',
                          iconBg: const Color(0xFFEFF6FF),
                          title: 'Credit & Debit Cards',
                          subtitle: 'Visa, Mastercard, Amex, Rupay and more',
                        ),
                      ]),
                      _optionCard(context, children: [
                        _optionRow(
                          context,
                          tileId: 'netbanking',
                          interactive: false,
                          iconAsset: 'assets/NewIcons/net_banking.png',
                          iconBg: const Color(0xFFF5F3FF),
                          title: 'Net Banking',
                          subtitle: '40+ Banks available',
                          tag: 'Fingerprint/Face ID',
                        ),
                        _optionRow(
                          context,
                          tileId: 'paylater',
                          interactive: false,
                          iconAsset: 'assets/NewIcons/pay_later.png',
                          iconBg: const Color(0xFFECFEFF),
                          title: 'Pay Later',
                          subtitle: 'LazyPay, Simpl, ICICI PayLater and more',
                        ),
                        _optionRow(
                          context,
                          tileId: 'giftcard',
                          interactive: false,
                          iconAsset: 'assets/NewIcons/wallet.png',
                          iconBg: const Color(0xFFFFFBEB),
                          title: 'Gift Cards & e-Wallets',
                          subtitle: 'Paytm, PhonePe, Amazon Pay and more',
                        ),
                      ]),
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
    // final minutes = _timeLeft.inMinutes.toString().padLeft(2, '0');
    // final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    return Padding(
      padding:
      EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _processing ? null : () => Navigator.of(context).maybePop(),
            child: Image.asset(
              'assets/NewIcons/arrowBack.png',
              width: context.w(15),
              height: context.h(15),
              color: Colors.black,
            ),
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
          Icon(
            Icons.timer,
            size: context.w(16),
            color: _expired ? const Color(0xffB42318) : _pri,
          ),
          SizedBox(width: context.w(4)),
          Text(
            '$_minutes:$_seconds',
            // '$minutes:$seconds',
            style: TextStyle(
              fontSize: context.fs(14),
              fontWeight: FontWeight.w600,
              color: _expired ? const Color(0xffB42318) : _pri,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TOTAL DUE ====================
  /// "New Delhi to Dubai" from the real city names, with the IATA codes as a
  /// fallback when GetSPricer didn't supply them.
  String get _routeLabel {
    final from = (widget.route.fromCity ?? '').trim();
    final to = (widget.route.toCity ?? '').trim();
    final start = from.isNotEmpty ? from : widget.route.from;
    final end = to.isNotEmpty ? to : widget.route.to;
    return '$start to $end';
  }

  Widget _totalDue(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showFareTopSheet(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Due',
                  style: TextStyle(
                    fontSize: context.fs(22),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  _routeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(13), color: _muted),
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(8)),
          Text(
            _displayAmount(_totalChargeInInr),
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

  /// "ONE WAY" / "ROUND TRIP" / "MULTI CITY" from the leg list.
  String get _tripType {
    if (widget.additionalLegs.isEmpty) return 'ONE WAY';
    final backToOrigin = widget.additionalLegs.length == 1 &&
        widget.additionalLegs.first.to.trim().toLowerCase() ==
            widget.route.from.trim().toLowerCase();
    return backToOrigin ? 'ROUND TRIP' : 'MULTI CITY';
  }

  /// Fare breakup as a drawer that slides down from the TOP — Figma "Total
  /// drop flight" (node 519:3907): a #FFFFFF → #80DAFF gradient panel with
  /// square top / 24px-rounded bottom corners and the close button floating
  /// centred below it. Uses the exact figures the charge is built from — no
  /// new pricing logic. Local to this screen so the bottom-sheet variant the
  /// other screens use is untouched.
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
    final travellers =
        widget.travellers.isNotEmpty ? widget.travellers : [widget.leadPassenger];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _fareGradient,
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
                padding: EdgeInsets.fromLTRB(context.w(16), context.h(24),
                    context.w(16), context.h(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Total Due header (tap to collapse) ----
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _processing ? null : () => Navigator.of(context).maybePop(),
                                child: Image.asset(
                                  'assets/NewIcons/arrowBack.png',
                                  width: context.w(15),
                                  height: context.h(15),
                                  color: Colors.black,
                                ),
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
                              Icon(
                                Icons.timer,
                                size: context.w(16),
                                color: _expired ? const Color(0xffB42318) : _pri,
                              ),
                              SizedBox(width: context.w(4)),
                              Text(
                                '$_minutes:$_seconds',
                                style: TextStyle(
                                  fontSize: context.fs(14),
                                  fontWeight: FontWeight.w600,
                                  color: _expired ? const Color(0xffB42318) : _pri,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.h(24),),
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
                              SizedBox(width: context.w(8)),
                              Text(
                                _displayAmount(_totalChargeInInr),
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
                    _fareLine(context, 'Fare', _displayAmount(widget.netAmount)),
                    if (_insurancePremiumInInr > 0) ...[
                      SizedBox(height: context.h(14)),
                      _fareLine(context, 'Trip Secure',
                          _displayAmount(_insurancePremiumInInr)),
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
                          _tripType,
                          style: TextStyle(
                            fontSize: context.fs(9),
                            fontWeight: FontWeight.w700,
                            color: _pri,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    for (final leg in [widget.route, ...widget.additionalLegs]) ...[
                      SizedBox(height: context.h(14)),
                      _flightSummaryCard(context, leg),
                    ],
                    for (var i = 0; i < travellers.length; i++) ...[
                      SizedBox(height: context.h(14)),
                      _passengerCard(context, travellers[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.h(12)),
        // ---- close, floating centred below the drawer ----
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
          style: TextStyle(
            color: _ink,
            fontSize: context.fs(13),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(8)),
            child: Container(
              height: 0.6,
              color: AppColors.lightsubhead,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: _ink,
            fontSize: context.fs(13),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
  /// Flight summary card inside the fare drawer — "New Delhi → Dubai
  /// (Non-stop)" + the departure / arrival date-time line.
  Widget _flightSummaryCard(BuildContext context, FlightRouteSegment leg) {
    final from = (leg.fromCity ?? '').trim().isNotEmpty
        ? leg.fromCity!.trim()
        : leg.from;
    final to =
        (leg.toCity ?? '').trim().isNotEmpty ? leg.toCity!.trim() : leg.to;
    final stops = (leg.stops ?? 0) <= 0
        ? 'Non-stop'
        : '${leg.stops} Stop${(leg.stops ?? 0) > 1 ? 's' : ''}';
    final date = leg.departureDate?.trim() ?? '';
    final when = [
      if (date.isNotEmpty) date,
      '${leg.departureTime} - ${leg.arrivalTime}',
    ].join('  |  ');

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(38),
            height: context.w(38),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pri,
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
            child: Icon(Icons.flight_rounded, size: context.w(20), color: Colors.white),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$from → $to ($stops)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(13),
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                SizedBox(height: context.h(3)),
                Text(
                  when,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.fs(11), color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Passenger card inside the fare drawer — "ANJLI SINGH (F)" + phone.
  Widget _passengerCard(BuildContext context, Map<String, dynamic> p) {
    String s(String k) => (p[k] ?? '').toString().trim();
    final name = '${s('firstName')} ${s('lastName')}'.trim().toUpperCase();
    final gender = s('gender');
    final gi = gender.isNotEmpty ? ' (${gender[0].toUpperCase()})' : '';
    final phone = s('mobileNumber');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: AppColors.white, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.isEmpty ? 'Guest' : '$name$gi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: 0.3,
            ),
          ),
          if (phone.isNotEmpty) ...[
            SizedBox(height: context.h(3)),
            Text(
              '+91-$phone',
              style: TextStyle(fontSize: context.fs(11), color: _muted),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== OPTIONS ====================
  Widget _sectionLabel(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
      fontSize: context.fs(16),
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
  );

  /// A white bordered card that groups one or more [_optionRow]s. Rows inside
  /// stack with NO divider between them (per the Figma).
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

  /// Green promo strip shown above a payment card (e.g. "Get extra discount
  /// on UPI of Rs 32"). Purely informational.
  Widget _promoStrip(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(12)),
      padding: EdgeInsets.symmetric(
          horizontal: context.w(14), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: _offer.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: _offer.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.discount_rounded, size: context.w(18), color: _offer),
          // Image.asset(
          //   'assets/NewIcons/discount.png',
          //   width: context.w(18),
          //   height: context.h(18),
          // ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.fs(12.5),
                fontWeight: FontWeight.w600,
                color: _ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One payment option ROW — no card chrome of its own, so it can be the
  /// sole child of a card or stacked with siblings inside a shared card.
  /// One tap on an interactive row selects the method and immediately kicks
  /// off [_processPayment] (there is no separate Pay button any more).
  Widget _optionRow(
      BuildContext context, {
        required String tileId,
        String? method, // 'wallet' | 'razorpay' — what _processPayment runs
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
      padding:
      EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(14)),
      color: isSelected ? _pri.withValues(alpha: 0.05) : Colors.white,
      child: Row(
        children: [
          iconAsset != null
              ? Image.asset(iconAsset,
              width: context.w(34), height: context.w(34))
              : Icon(icon,
                  size: context.w(22),
                  color: iconColor == Colors.transparent ? _ink : iconColor),
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
                        style: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                    if (tag != null) ...[
                      SizedBox(width: context.w(6)),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.w(6), vertical: context.h(2)),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(context.r(4)),
                          ),
                          child: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(9),
                              fontWeight: FontWeight.w800,
                              color: tagColor,
                              letterSpacing: 0.3,
                            ),
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
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            size: context.w(22),
            color: isSelected ? _pri : AppColors.AppBlue,
          ),
        ],
      ),
    );

    if (!interactive || method == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (_expired || _processing)
          ? null
          : () => _payWith(method, tileId),
      child: content,
    );
  }

  /// One-tap: remember the method for [_processPayment]'s existing routing,
  /// then start it. No behaviour change to wallet / Razorpay themselves.
  void _payWith(String method, String tileId) {
    if (_expired || _processing) return;
    setState(() {
      _selectedTileId = tileId;
      _selectedPaymentMethod = method;
      _errorMessage = null;
    });
    _processPayment();
  }

  // ==================== STATUS / PAY ====================
  Widget _processingCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(48)),
      child: Column(
        children: [
          const CircularProgressIndicator(color: _pri),
          SizedBox(height: context.h(16)),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: context.fs(13)),
          ),
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
          Icon(Icons.error_outline_rounded,
              size: context.w(16), color: const Color(0xffB42318)),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              message,
              style:
              TextStyle(color: const Color(0xffB42318), fontSize: context.fs(12)),
            ),
          ),
        ],
      ),
    );
  }

}