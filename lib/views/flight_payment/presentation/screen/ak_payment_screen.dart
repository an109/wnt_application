import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// Standard Checkout (razorpay_flutter) is retired for this screen in favour
// of Razorpay Custom Checkout below — kept commented, not deleted, per the
// migration notes.
// import 'package:razorpay_flutter/razorpay_flutter.dart';
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
import 'package:wander_nova/core/services/push_notification_service.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/booking_screen.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/card_form.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/checkout_ui.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/method_sections.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/upi_section.dart';
import 'package:wander_nova/views/flight_search/presentation/screen/seat_addons_screen.dart';
import 'package:wander_nova/views/flight_ticket/presentation/screen/ak_ticket_confirmation_screen.dart';
import 'package:wander_nova/views/wallet/data/data_source/wallet_api_service.dart';
import 'package:wander_nova/views/benefits/data/data_source/benefit_api_service.dart';
import 'package:wander_nova/views/benefits/domain/entity/benefit_entity.dart';
import 'package:wander_nova/views/benefits/presentation/widget/benefit_apply_card.dart';
import 'package:wander_nova/common_widgets/currency_scope.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';

/// Payment + ticketing for the Akbar flow. CreateItinerary has already
/// persisted the full booking server-side by session_id before this screen
/// runs, so — unlike the old TBO flow — there is no "prepare ticket" payload
/// to build client-side: this screen only charges the customer and then
/// tells the backend (via StartPay) to issue the ticket against that
/// session_id.
class AkFlightPaymentScreen extends StatefulWidget {
  final FlightRouteSegment route;
  final Map<String, dynamic> leadPassenger;
  /// Retail/gross amount to charge the customer (CreateItinerary's GrossAmount).
  /// Despite the field name, this is the published fare — what the user pays.
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

  /// Promo code applied on the booking screen, shown on the fare breakdown.
  final String promoCode;

  /// [promoCode]'s discount in INR. CreateItinerary's [netAmount] knows
  /// nothing about Wander Nova promos, so the discount is taken off here —
  /// this is what keeps the fare the traveller was quoted at the offer step
  /// from reappearing at full price on the payment screen.
  final double promoDiscountInInr;

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
    this.promoCode = '',
    this.promoDiscountInInr = 0,
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

  // late final Razorpay _razorpay; // Standard Checkout — retired, see below.

  /// Set once the first Razorpay Custom Checkout attempt creates an order,
  /// then reused by every method screen (card/UPI/netbanking/wallet) — an
  /// order must be created exactly once and ties to one successful payment
  /// (doc step 1.3), so this is intentionally memoized rather than
  /// re-created per tile tap.
  String? _razorpayOrderId;
  String? _razorpayKeyId;

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

  // Inline accordion payment sections
  String? _open;
  final _rzService = RazorpayCustomCheckoutService();
  late final Future<List<UpiApp>> _upiApps = _rzService.getUpiApps().catchError((_) => <UpiApp>[]);
  Future<Map<String, dynamic>>? _methods;

  // Razorpay's payment id — the real gateway transaction reference, shown on
  // the confirmation screen. Null for wallet payments (no gateway involved).
  String? _transactionId;

  // Set once /wallet/pay-booking/ has charged the wallet for this booking, so
  // a retry after a failed StartPay never charges it a second time.
  String? _walletDebitRef;

  static const _maxStartPayAttempts = 6;
  static const _defaultRetryDelaySeconds = 5;

  String get _sessionId => widget.route.sessionId ?? '';

  /// Akbar amounts (netAmount, wallet balance) are always in INR — this
  /// converts to whatever currency the user has picked in Settings, instead
  /// of always showing a hardcoded ₹.
  /// Amounts on this page are charged in INR, so they are shown in INR;
  /// the "≈" line under Total Due gives the user's own currency.
  String _displayAmount(double amountInInr) => CurrencyConverter.format(amountInInr, 'INR');

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
  double get _totalChargeInInr {
    final total = widget.netAmount -
        _promoDiscountInInr -
        _benefitAppliedInInr +
        _insurancePremiumInInr;
    return total < _minChargeInInr ? _minChargeInInr : total;
  }

  // ── Benefit credit ───────────────────────────────────────────────────────
  // What the server says this booking may absorb. Null until /benefits/quote/
  // answers, which is also the "not signed in / programme off" state — in
  // both cases the card renders nothing and checkout is unchanged.
  BenefitQuote? _benefitQuote;

  /// How much benefit credit the traveller chose to apply.
  double _benefitApplied = 0;

  /// Set once the credit is reserved server-side. Must be captured after a
  /// successful payment or released after a failed one — a reference left
  /// dangling ties up the traveller's credit until its TTL expires.
  String? _benefitHoldRef;

  /// Applied credit, but never more than the fare it is discounting. Trip
  /// Secure is a separate product the insurer still has to be paid for, so
  /// benefit credit cannot eat into the premium — same rule as the promo.
  double get _benefitAppliedInInr {
    if (_benefitApplied <= 0) return 0;
    final roomLeft = widget.netAmount - _promoDiscountInInr;
    if (roomLeft <= 0) return 0;
    return _benefitApplied > roomLeft ? roomLeft : _benefitApplied;
  }

  /// The margin on this fare, when this screen knows it.
  ///
  /// Akbar reports both numbers — NetAmount is what we owe the airline,
  /// GrossAmount is the published fare — and the difference is what the
  /// booking actually earns. Sending it lets the server cap against reality
  /// rather than its deliberately low fallback, which on a zero-margin fare
  /// correctly yields no redemption at all.
  ///
  /// This screen is currently only handed `netAmount`, so it returns null and
  /// the server applies `assumed_margin_percent` (1% for flights) instead.
  /// Threading GrossAmount down from GetSPricer would make the offer more
  /// generous on the fares that can afford it; until then the conservative
  /// fallback is the safe behaviour, not a bug.
  double? get _bookingMarginInInr => null;

  /// The promo discount actually taken off, capped at the flight's net amount
  /// so a generous promo discounts the fare but never the Trip Secure premium
  /// (which is a separate product the insurer still has to be paid for).
  double get _promoDiscountInInr {
    final discount = widget.promoDiscountInInr;
    if (discount <= 0) return 0;
    return discount > widget.netAmount ? widget.netAmount : discount;
  }

  /// Razorpay rejects an order below ₹1, so a promo that wipes out the whole
  /// fare still leaves a ₹1 charge rather than an order the gateway refuses.
  static const double _minChargeInInr = 1;

  @override
  void initState() {
    super.initState();
    // Standard Checkout wiring — retired in favour of Razorpay Custom
    // Checkout (see _startCardCheckout / _startUpiCheckout / etc. below).
    // _razorpay = Razorpay();
    // _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    // _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    // _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);

    _loadBenefitQuote();

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
    // _razorpay.clear();
    super.dispose();
  }

  /// Routes payment to the flow matching [_selectedPaymentMethod]. Only
  /// 'wallet' (WanderNova wallet balance) still runs through this — every
  /// Razorpay Custom Checkout method (card/UPI/netbanking/wallet-provider)
  /// is launched directly from its own tile via _startCardCheckout() etc.
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() => _errorMessage = 'Please select a payment method');
      return;
    }
    // Reserve the benefit credit before any money moves. If the server has
    // changed its mind about the cap, the total on screen is stale and the
    // payment must not proceed at it.
    if (!await _reserveBenefit()) return;

    if (_selectedPaymentMethod == 'wallet') {
      await _payWithWallet();
      return;
    }
  }

  // ── Benefit credit: quote → hold → capture/release ───────────────────────

  /// Asks the server what this booking may absorb. Failure is silent on
  /// purpose: a guest, a disabled programme and a network blip should all
  /// just mean "no benefit row", never a blocked checkout.
  Future<void> _loadBenefitQuote() async {
    if (!sl<PreferencesManager>().isLoggedIn()) return;
    try {
      final q = await sl<BenefitApiService>().quote(
        bookingType: 'flight',
        amount: widget.netAmount - _promoDiscountInInr,
        marginAmount: _bookingMarginInInr,
      );
      if (!mounted) return;
      setState(() => _benefitQuote = q);
    } catch (e) {
      print('Benefit quote skipped: $e');
    }
  }

  /// Reserves the chosen credit before the gateway opens.
  ///
  /// Returns false only when the traveller wanted credit and the server
  /// refused it — in that case the amount they were shown is no longer true,
  /// so the payment must not go ahead at the old total.
  Future<bool> _reserveBenefit() async {
    if (_benefitAppliedInInr <= 0) return true;
    if (_benefitHoldRef != null) return true; // already held on an earlier try

    final h = await sl<BenefitApiService>().hold(
      bookingType: 'flight',
      amount: widget.netAmount - _promoDiscountInInr,
      redeemAmount: _benefitAppliedInInr,
      marginAmount: _bookingMarginInInr,
      bookingRef: _sessionId,
    );

    if (!mounted) return false;
    if (!h.success) {
      setState(() {
        _benefitApplied = 0;
        _errorMessage = h.error.isNotEmpty
            ? h.error
            : 'Your benefit credit could not be applied. Please review the total.';
      });
      await _loadBenefitQuote();
      return false;
    }

    setState(() {
      _benefitHoldRef = h.holdReference;
      // The server is the authority on the amount — if it granted less than
      // was asked for, the screen follows it rather than the other way round.
      _benefitApplied = h.appliedAmount;
    });
    return true;
  }

  /// Spends the held credit once payment has actually succeeded.
  ///
  /// Never fails the booking: the traveller has already paid and the flight is
  /// ticketed, so an unconvertible hold is a reconciliation job for the server
  /// (and expires on its own), not a reason to show an error here.
  Future<void> _captureBenefit() async {
    final ref = _benefitHoldRef;
    if (ref == null) return;
    _benefitHoldRef = null;
    await sl<BenefitApiService>().capture(ref, bookingRef: _sessionId);
  }

  /// Hands the credit back after a failed or abandoned payment.
  Future<void> _releaseBenefit({String reason = 'Payment not completed'}) async {
    final ref = _benefitHoldRef;
    if (ref == null) return;
    _benefitHoldRef = null;
    await sl<BenefitApiService>().release(ref, reason: reason);
    if (mounted) setState(() => _benefitApplied = 0);
  }

  /// Pays from the wallet: /wallet/pay-booking/ debits it against the
  /// session id (what StartPay's payment guard looks for, same as the
  /// website), then StartPay runs with gateway 'wallet'.
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

    // Already charged on an earlier try whose StartPay failed — StartPay is
    // idempotent per session, so retry it against that same debit.
    if (_walletDebitRef != null) {
      await _runStartPayWithRetry(gateway: 'wallet');
      return;
    }

    try {
      final response = await sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;

      if (balance >= _totalChargeInInr) {
        // Last word before the money leaves the wallet. A wallet debit has
        // no gateway sheet of its own to pause on, so without this the tap
        // that opens "My Wallet" is also the tap that spends the balance.
        setState(() => _processing = false);
        final confirmed = await _confirmWalletPayment(balance);
        if (!mounted || !confirmed) return;
        setState(() {
          _processing = true;
          _errorMessage = null;
        });
        if (await _debitWallet()) await _runStartPayWithRetry(gateway: 'wallet');
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

  /// Confirmation sheet shown before the wallet is debited: what leaves, what
  /// is there now, and what is left after. Returns false on dismiss, so a
  /// stray tap or a back gesture never spends the balance.
  Future<bool> _confirmWalletPayment(double balance) async {
    final remaining = balance - _totalChargeInInr;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(20))),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(20),
            context.h(10),
            context.w(20),
            context.h(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: context.w(40),
                  height: context.h(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E7F0),
                    borderRadius: BorderRadius.circular(context.r(99)),
                  ),
                ),
              ),
              SizedBox(height: context.h(18)),
              Text(
                'Confirm wallet payment',
                style: TextStyle(
                  color: _ink,
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: context.h(4)),
              Text(
                _routeLabel,
                style: TextStyle(
                  color: AppColors.subhead,
                  fontSize: context.fs(12),
                ),
              ),
              SizedBox(height: context.h(18)),
              _walletConfirmRow(context, 'Amount to pay',
                  _displayAmount(_totalChargeInInr), emphasise: true),
              SizedBox(height: context.h(10)),
              _walletConfirmRow(
                  context, 'Wallet balance', _displayAmount(balance)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.h(10)),
                child: const Divider(height: 1, color: Color(0xFFE6E8EC)),
              ),
              _walletConfirmRow(context, 'Balance after payment',
                  _displayAmount(remaining < 0 ? 0 : remaining)),
              SizedBox(height: context.h(20)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: context.h(46),
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E7F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(12)),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: _ink,
                            fontSize: context.fs(13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: SizedBox(
                      height: context.h(46),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.OrangeColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(12)),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'PAY ${_displayAmount(_totalChargeInInr)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.fs(13),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Widget _walletConfirmRow(BuildContext context, String label, String amount,
      {bool emphasise = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasise ? _ink : AppColors.subhead,
              fontSize: context.fs(13),
              fontWeight: emphasise ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: _ink,
            fontSize: context.fs(emphasise ? 17 : 13),
            fontWeight: emphasise ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Charges the wallet for this booking (whole rupees, rounded up, as the
  /// website does). Returns false, with the reason shown, if it wasn't charged.
  Future<bool> _debitWallet() async {
    setState(() => _statusMessage = 'Paying from your wallet...');
    final debit = await sl<WalletApiService>().payBooking(
      amount: _totalChargeInInr.ceilToDouble(),
      bookingType: 'flight',
      bookingRef: _sessionId,
      description: 'Flight: ${widget.route.from} → ${widget.route.to}',
    );
    if (!mounted) return false;
    if (debit.success) {
      _walletDebitRef = debit.reference ?? _sessionId;
      return true;
    }
    setState(() {
      _processing = false;
      _errorMessage = debit.error ?? 'Wallet payment failed. Please try again.';
    });
    return false;
  }

  // ---- Standard Checkout (retired) ----
  // Future<void> _initiatePayment() async {
  //   if (_sessionId.isEmpty) {
  //     setState(() => _errorMessage = 'Booking session expired. Please start over.');
  //     return;
  //   }
  //
  //   setState(() {
  //     _processing = true;
  //     _errorMessage = null;
  //     _statusMessage = 'Opening secure payment...';
  //   });
  //
  //   try {
  //     final dio = sl<DioClient>().instance;
  //     final response = await dio.post(
  //       Urls.razorpayCreateOrder,
  //       data: {
  //         'amount': _totalChargeInInr,
  //         'currency': 'INR',
  //         'reference_id': _sanitizedOrderId(_sessionId),
  //       },
  //     );
  //
  //     final orderId = response.data['order_id'] as String?;
  //     final keyId = response.data['key_id'] as String?;
  //
  //     if (!mounted) return;
  //     setState(() => _processing = false);
  //
  //     final firstName = (widget.leadPassenger['firstName'] ?? '').toString();
  //     final lastName = (widget.leadPassenger['lastName'] ?? '').toString();
  //     final email = (widget.leadPassenger['email'] ?? '').toString();
  //     final phone = (widget.leadPassenger['mobileNumber'] ?? '').toString();
  //
  //     _razorpay.open({
  //       'key': keyId ?? '',
  //       'amount': (_totalChargeInInr * 100).toInt(),
  //       'currency': 'INR',
  //       'name': 'WanderNova',
  //       'description': 'Flight ${widget.route.from} → ${widget.route.to}',
  //       'order_id': orderId ?? '',
  //       'prefill': {
  //         'name': '$firstName $lastName'.trim(),
  //         'email': email,
  //         'contact': phone,
  //       },
  //       'theme': {'color': '#1769F6'},
  //     });
  //   } on DioException catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _processing = false;
  //       _errorMessage = 'Could not create payment order. Please try again.';
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _processing = false;
  //       _errorMessage = 'Could not start payment: $e';
  //     });
  //   }
  // }
  //
  // void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
  //   await _verifyAndConfirmBooking(
  //     paymentId: response.paymentId,
  //     orderId: response.orderId,
  //     signature: response.signature,
  //   );
  // }
  //
  // void _handleRazorpayError(PaymentFailureResponse response) {
  //   if (!mounted) return;
  //   setState(() {
  //     _processing = false;
  //     _errorMessage = 'Payment failed: ${response.message ?? 'Please try again.'}';
  //   });
  // }
  //
  // void _handleRazorpayExternalWallet(ExternalWalletResponse response) {}

  // ---- Razorpay Custom Checkout ----

  /// Creates the Razorpay order the first time the customer taps ANY
  /// Custom Checkout method, and reuses it afterwards — an order is created
  /// exactly once per payment attempt (doc step 1.3: "Payments made without
  /// an order_id ... will be automatically refunded"), so switching between
  /// method screens (e.g. Card → back → UPI) must never create a second one.
  /// reference_id equals session_id so StartPay's payment guard can match
  /// the paid transaction to this booking session, same as the old flow.
  Future<bool> _ensureRazorpayOrder() async {
    if (_razorpayOrderId != null && _razorpayKeyId != null) return true;

    if (_sessionId.isEmpty) {
      setState(() => _errorMessage = 'Booking session expired. Please start over.');
      return false;
    }

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
          'amount': _totalChargeInInr,
          'currency': 'INR',
          'reference_id': _sanitizedOrderId(_sessionId),
          // Same as the website: tells the backend (webhook reconciliation)
          // what this payment is for.
          'transaction_type': 'flight',
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
      print('Razorpay order error: ${e.message}');
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
          'amount': (_totalChargeInInr * 100).round(),
          'currency': 'INR',
          'order_id': _razorpayOrderId,
          'email': (widget.leadPassenger['email'] ?? '').toString(),
          'contact': (widget.leadPassenger['mobileNumber'] ?? '').toString(),
          'description': 'Flight ${widget.route.from} → ${widget.route.to}',
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

  /// Shared by every Custom Checkout method screen: verifies the signature
  /// server-side (unchanged endpoint/contract from the old Standard
  /// Checkout flow), then continues exactly as before — StartPay, retrieve
  /// booking, Trip Secure, navigate to the ticket screen.
  Future<void> _verifyAndConfirmBooking({
    required String? paymentId,
    required String? orderId,
    required String? signature,
  }) async {
    setState(() {
      _processing = true;
      _statusMessage = 'Verifying payment...';
      _errorMessage = null;
      _transactionId = paymentId;
    });

    try {
      final dio = sl<DioClient>().instance;
      final verifyResponse = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
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
          // Paid and ticketed — the held credit is now genuinely spent.
          await _captureBenefit();
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
        // Extract message from error response body (e.g. 502 booking_failed)
        if (result is DataFailed) {
          final body = (result as DataFailed).error?.response?.data;
          if (body is Map) {
            final apiMsg = body['message']?.toString() ?? '';
            if (apiMsg.isNotEmpty && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(apiMsg),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;
      }
    }

    final stillPending = attempt >= _maxStartPayAttempts;

    // Hard failure: the booking is not happening, so give the credit back now
    // rather than making the traveller wait out the hold's TTL.
    //
    // A *pending* booking is deliberately left alone. It may still confirm,
    // and releasing here would hand back credit for a trip that then gets
    // ticketed. Leaving the hold means the TTL returns it if the booking
    // never lands — the safer of the two wrong answers, since the alternative
    // is charging someone for a booking that failed.
    if (!stillPending) {
      await _releaseBenefit(reason: 'Booking could not be completed');
    }

    final message = stillPending
        ? 'Your booking is still being confirmed. Please check My Bookings shortly.'
        : 'Payment succeeded but ticketing failed. Please contact support with your booking reference.';

    await _notifyBookingOutcome(
      title: stillPending ? 'Booking pending' : 'Booking failed',
      body: stillPending
          ? '$_routeLabel — we are still confirming it. We will have an answer shortly; your payment is safe.'
          : '$_routeLabel — payment went through but ticketing did not. Contact support with your booking reference.',
    );

    if (!mounted) return;
    setState(() {
      _processing = false;
      _errorMessage = message;
    });
  }

  /// Raises the device-local booking notification. Keyed on the session so
  /// a pending booking that later resolves replaces its own earlier notice
  /// instead of stacking a second one.
  Future<void> _notifyBookingOutcome({
    required String title,
    required String body,
  }) {
    return PushNotificationService.instance.showBookingUpdate(
      title: title,
      body: body,
      reference: _sessionId,
    );
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

      final pnr = result.data!.pnrs.isNotEmpty ? result.data!.pnrs.first : '';
      await _notifyBookingOutcome(
        title: 'Booking confirmed',
        body: pnr.isEmpty
            ? '$_routeLabel is booked. Your e-ticket is ready in My Trips.'
            : '$_routeLabel is booked. PNR $pnr — your e-ticket is ready in My Trips.',
      );
      if (!mounted) return;

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
            // What was actually charged, not the pre-promo fare — the ticket
            // screen labels this "Amount actually paid".
            netAmount: _totalChargeInInr,
            travellerCount: widget.travellerCount,
            travellerNames: widget.travellerNames,
          ),
        ),
      );
    } else {
      await _notifyBookingOutcome(
        title: 'Booking confirmed',
        body: '$_routeLabel is booked, but the ticket details did not load. '
            'Open My Trips to see it.',
      );
      if (!mounted) return;
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

  /// Asks before abandoning checkout.
  ///
  /// Leaving really is final: the fare is committed against this session and
  /// the hold expires, so there is no "come back and finish" — the traveller
  /// has to search and price the flight again. Returns true if they still
  /// want to leave.
  Future<bool> _confirmLeave() async {
    if (_processing) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(16)),
        ),
        title: Text(
          'Leave without paying?',
          style: TextStyle(
            fontSize: context.fs(18),
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        content: Text(
          'This booking is held at ${_displayAmount(_totalChargeInInr)} only '
          'until the timer runs out. Going back ends the session — the seats '
          'are released and you will have to search again, where the fare may '
          'be different.',
          style: TextStyle(
            fontSize: context.fs(13),
            height: 1.45,
            color: _muted,
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(
            context.w(12), 0, context.w(12), context.h(10)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'STAY & PAY',
              style: TextStyle(
                color: _ink,
                fontSize: context.fs(13),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffB42318),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
            ),
            child: Text(
              'LEAVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.fs(13),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shared by the header arrow and the system back gesture, so both routes
  /// out of checkout ask the same question.
  Future<void> _handleBack() async {
    if (!await _confirmLeave()) return;
    // Leaving mid-checkout: return the reserved credit immediately so it is
    // spendable again on the next attempt instead of looking "missing".
    await _releaseBenefit(reason: 'Left the payment screen');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Never pops on its own: the gesture is intercepted so the warning can
      // run first, and _handleBack pops once the traveller confirms.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Divider(height: 1, color: _stroke),
            Expanded(
              // While the booking is being confirmed the loader owns the
              // page, so it sits centred in the space under Total Due
              // instead of butted up beneath it with the rest blank. No
              // scrolling in that state either — there is nothing to reach.
              child: _processing
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(context.w(16),
                          context.h(18), context.w(16), context.h(32)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _totalDue(context),
                          Expanded(
                            child: Center(child: _processingCard(context)),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                    context.w(16), context.h(18), context.w(16), context.h(32)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _totalDue(context),
                    SizedBox(height: context.h(24)),
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
                          amount: _totalChargeInInr,
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
                          payLabel: 'Pay ${formatInr(_totalChargeInInr)}',
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
                          amount: _totalChargeInInr,
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
                          amount: _totalChargeInInr,
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
                          amount: _totalChargeInInr,
                          busy: _processing,
                          methods: _loadMethods(),
                          onPayWallet: (w) => _payWithMethod({'method': 'wallet', 'wallet': w}),
                          onPayLater: (p) => _payWithMethod({'method': 'paylater', 'provider': p}),
                        ) : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            onTap: _processing ? null : _handleBack,
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
                if (context.moneyHint(_totalChargeInInr).isNotEmpty)
                  Text(
                    '${context.moneyHint(_totalChargeInInr)} · charged in INR',
                    style: TextStyle(fontSize: context.fs(12), color: _muted),
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
                    if (_promoDiscountInInr > 0) ...[
                      SizedBox(height: context.h(14)),
                      _fareLine(
                        context,
                        widget.promoCode.isEmpty
                            ? 'Promo Discount'
                            : 'Promo Discount (${widget.promoCode})',
                        '- ${_displayAmount(_promoDiscountInInr)}',
                      ),
                    ],
                    if (_benefitAppliedInInr > 0) ...[
                      SizedBox(height: context.h(14)),
                      _fareLine(
                        context,
                        'Benefit Credit',
                        '- ${_displayAmount(_benefitAppliedInInr)}',
                      ),
                    ],
                    if (_benefitQuote != null) ...[
                      SizedBox(height: context.h(6)),
                      BenefitApplyCard(
                        quote: _benefitQuote!,
                        appliedAmount: _benefitApplied,
                        money: _displayAmount,
                        enabled: !_processing,
                        // Once reserved the figure belongs to the server for
                        // the rest of the attempt, so the controls go
                        // read-only rather than letting the traveller edit a
                        // number that is already held.
                        locked: _benefitHoldRef != null,
                        onChanged: (v) => setState(() => _benefitApplied = v),
                      ),
                    ],
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
  /// One tap on an interactive row either runs [_processPayment] (wallet)
  /// or its own [onTapOverride] (every Custom Checkout method), with no
  /// separate Pay button on this screen.
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

    if (!interactive || (method == null && onTapOverride == null)) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (_expired || _processing)
          ? null
          : (onTapOverride ?? () => _payWith(method!, tileId)),
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
            // Container(
            //   padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(7)),
            //   decoration: BoxDecoration(color: AppColors.AppBlue, borderRadius: BorderRadius.circular(context.r(8))),
            //   child: Text('PAY', style: TextStyle(fontSize: context.fs(12), fontWeight: FontWeight.w800, color: Colors.white)),
            // ),ayushgupta2534@gmail.com
          ]),
        ),
      ),
    );
  }

  // ==================== STATUS / PAY ====================
  Widget _processingCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(36)),
      child: BookingProgressLoader(message: _statusMessage),
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