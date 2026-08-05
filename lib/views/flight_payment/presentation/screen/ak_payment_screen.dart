import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/UI_helper/currency_converter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/logo.dart';
import 'package:wander_nova/core/constants/urls.dart';
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
    this.insuranceBookingContext,
  });

  @override
  State<AkFlightPaymentScreen> createState() => _AkFlightPaymentScreenState();
}

class _AkFlightPaymentScreenState extends State<AkFlightPaymentScreen> {
  static const _blue = Color(0xFF1769F6);
  static const _navy = Color(0xFF071638);
  static const _pageBg = Color(0xFFF3F6FC);

  late final Razorpay _razorpay;

  bool _processing = false;
  String _statusMessage = '';
  String? _errorMessage;

  // Null until the user picks a method, which keeps the Pay button disabled.
  // 'wallet' uses the wallet-balance flow; 'razorpay' opens the Razorpay
  // checkout.
  String? _selectedPaymentMethod;

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
  }

  @override
  void dispose() {
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
      amount: _insurancePremiumInInr,
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
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const WanderNovaLogo(scaleFactor: 0.6),
        backgroundColor: _pageBg,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.hp(4)),
              Container(
                padding: EdgeInsets.all(context.w(16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(14)),
                  border: Border.all(color: const Color(0xffE6ECFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.insuranceBookingContext != null) ...[
                      _amountRow(context, 'Flight fare', _displayAmount(widget.netAmount)),
                      SizedBox(height: context.h(6)),
                      _amountRow(context, 'Trip Secure', _displayAmount(_insurancePremiumInInr)),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: context.h(10)),
                        child: Divider(height: context.h(1), color: const Color(0xffE6ECFF)),
                      ),
                    ],
                    Text(
                      'Total Payable',
                      style: TextStyle(
                        color: const Color(0xff6B7280),
                        fontSize: context.fs(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      _displayAmount(_totalChargeInInr),
                      style: TextStyle(
                        color: _navy,
                        fontSize: context.fs(24),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.hp(3)),
              if (_processing) ...[
                const Center(child: CircularProgressIndicator(color: _blue)),
                SizedBox(height: context.h(12)),
                Center(
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: const Color(0xff4B5563), fontSize: context.fs(13)),
                  ),
                ),
              ] else ...[
                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(context.w(12)),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF2F2),
                      borderRadius: BorderRadius.circular(context.r(10)),
                      border: Border.all(color: const Color(0xffFCA5A5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: const Color(0xffB42318), fontSize: context.fs(12)),
                    ),
                  ),
                  SizedBox(height: context.h(16)),
                ],
                _paymentMethodSection(context),
                SizedBox(height: context.h(16)),
                SizedBox(
                  height: context.buttonHeight + 10,
                  child: ElevatedButton(
                    onPressed: _selectedPaymentMethod == null ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      disabledBackgroundColor: const Color(0xffD1D5DB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(18)),
                      ),
                    ),
                    child: Text(
                      _selectedPaymentMethod == null ? 'Select a payment method' : 'Pay Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: context.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountRow(BuildContext context, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: const Color(0xff6B7280), fontSize: context.fs(12.5)),
        ),
        Text(
          amount,
          style: TextStyle(color: _navy, fontSize: context.fs(12.5), fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _paymentMethodSection(BuildContext context) {
    const methods = [
      {
        'id': 'wallet',
        'name': 'My Wallet',
        'subtitle': 'Pay using your wallet balance',
        'icon': Icons.account_balance_wallet,
      },
      {
        'id': 'razorpay',
        'name': 'Razorpay',
        'subtitle': 'Cards, UPI, Net Banking, Wallets',
        'icon': Icons.payment,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Payment Method',
          style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.bold, color: _navy),
        ),
        SizedBox(height: context.h(10)),
        for (final method in methods) ...[
          _paymentMethodTile(
            context,
            id: method['id'] as String,
            name: method['name'] as String,
            subtitle: method['subtitle'] as String,
            icon: method['icon'] as IconData,
          ),
          SizedBox(height: context.h(8)),
        ],
      ],
    );
  }

  Widget _paymentMethodTile(
    BuildContext context, {
    required String id,
    required String name,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPaymentMethod = isSelected ? null : id;
        _errorMessage = null;
      }),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: isSelected ? _blue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: isSelected ? _blue : const Color(0xffE6ECFF), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.w(20), color: isSelected ? _blue : const Color(0xff6B7280)),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: context.fs(13), fontWeight: FontWeight.w600, color: _navy),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: context.fs(10.5), color: const Color(0xff6B7280)),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: _blue, size: context.w(20)),
          ],
        ),
      ),
    );
  }
}
