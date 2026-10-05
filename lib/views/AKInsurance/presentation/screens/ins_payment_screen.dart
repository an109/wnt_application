import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../countries/domain/entities/country_entity.dart';
import '../../../countries/presentation/bloc/country_bloc.dart';
import '../../../countries/presentation/bloc/country_state.dart';
// The native Razorpay Custom Checkout bridge and the method widgets are
// shared infrastructure, not another module's screen: the service is the one
// MethodChannel wrapper around the SDK registered in MainActivity/AppDelegate,
// and the sections are the same pieces the wallet uses. Both are consumed
// unmodified, so nothing here can change how another flow behaves.
import '../../../flight_payment/data/razorpay_custom_checkout_service.dart';
import '../../../wallet/wallet/screen/checkout/card_form.dart';
import '../../../wallet/wallet/screen/checkout/checkout_ui.dart';
import '../../../wallet/wallet/screen/checkout/method_sections.dart';
import '../../../wallet/wallet/screen/checkout/upi_section.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../service/ins_policy_issuer.dart';
import '../state/ins_booking_details.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_plan_card.dart';
import 'ins_confirmed_screen.dart';

/// "Payment" — Figma `Payment option INSURANCE 1` / `… 2`.
///
/// The whole charge happens on this one screen: there is no second method
/// screen to push into. The flow is
///
///   1. `Urls.razorpayCreateOrder` mints an order (`transaction_type:
///      insurance`)
///   2. the traveller picks a method here and the native Razorpay Custom
///      Checkout SDK charges it
///   3. `Urls.razorpayVerify` checks the signature server-side
///   4. **StartPay** issues the real policy against the agent balance
///
/// Step 4 only ever runs after a cleared, verified charge — the policy is
/// never issued on an unverified payment.
class InsPaymentScreen extends StatefulWidget {
  final AkInsurancePlanEntity plan;
  final InsSearchQuery query;
  final String tui;
  final InsBookingDetails details;
  final double amount;

  const InsPaymentScreen({
    super.key,
    required this.plan,
    required this.query,
    required this.tui,
    required this.details,
    required this.amount,
  });

  @override
  State<InsPaymentScreen> createState() => _InsPaymentScreenState();
}

class _InsPaymentScreenState extends State<InsPaymentScreen> {
  final _checkout = RazorpayCustomCheckoutService();

  bool _busy = false;
  String _status = '';
  String? _error;

  String? _orderId;
  String? _keyId;

  /// The order's amount in paise exactly as the gateway minted it.
  ///
  /// The charge has to be for this number, not for a second client-side
  /// conversion of the rupee premium: Razorpay rejects a payment whose amount
  /// does not match its order, and the two do not always agree. The insurer
  /// quotes fractional paise — a 478.6198 premium becomes 47861 paise on the
  /// order (truncated) but `(478.6198 * 100).round()` is 47862 here, so
  /// authorising the locally computed figure fails the order by one paisa.
  int? _orderAmountPaise;

  bool _summaryOpen = false;

  /// Which method panel is expanded, or null when all are collapsed. One at
  /// a time, as the wallet top-up checkout does.
  String? _open;

  late final Future<List<UpiApp>> _upiApps =
      _checkout.getUpiApps().catchError((_) => <UpiApp>[]);
  Future<Map<String, dynamic>>? _methods;

  /// How long the quoted premium is held before it has to be re-priced.
  static const _hold = Duration(minutes: 15);
  late final DateTime _deadline = DateTime.now().add(_hold);
  Timer? _ticker;
  Duration _left = _hold;

  /// One reference per attempt, so a retry re-uses the same Razorpay order
  /// rather than minting a second one that could never be settled.
  late final String _reference =
      'insurance-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    // The Razorpay order is minted as soon as the screen opens rather than on
    // the first method tap: the enabled-methods lookup needs the key id, so
    // Net Banking / EMI / Wallets would otherwise open against an empty key
    // and fail before the traveller had chosen anything.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureOrder();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _deadline.difference(DateTime.now());
      setState(() => _left = left.isNegative ? Duration.zero : left);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _expired => _left == Duration.zero;

  String get _clock {
    final m = _left.inMinutes.toString().padLeft(2, '0');
    final s = (_left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m :$s';
  }

  /// Only a fallback for an order that came back without an amount — see
  /// [_orderAmountPaise] for why the gateway's own figure is preferred.
  int get _amountInPaise => (widget.amount * 100).round();

  // ------------------------------------------------------------- 1. order

  Future<bool> _ensureOrder() async {
    if (_orderId != null && _keyId != null) return true;

    setState(() {
      _busy = true;
      _error = null;
      _status = 'Preparing payment…';
    });

    try {
      final dio = di.sl<DioClient>().instance;
      final userId = di.sl<PreferencesManager>().getUserId();
      final res = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'reference_id': _reference,
          'amount': widget.amount,
          'currency': 'INR',
          // Tells the backend's reconciliation what the charge is for.
          'transaction_type': 'insurance',
          if (userId != null) 'user_id': userId,
        },
      );

      final orderId = res.data['order_id'] as String?;
      final keyId = res.data['key_id'] as String?;
      final orderAmount = (res.data['amount'] as num?)?.round();
      if (!mounted) return false;

      if (orderId == null || keyId == null) {
        setState(() {
          _busy = false;
          _error = 'Could not create the payment order. Please try again.';
        });
        return false;
      }

      setState(() {
        _busy = false;
        _orderId = orderId;
        _keyId = keyId;
        _orderAmountPaise = orderAmount;
      });
      return true;
    } on DioException catch (_) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = 'Could not create the payment order. Please try again.';
      });
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = 'Could not start payment: $e';
      });
      return false;
    }
  }

  /// The account's enabled methods, so the netbanking/EMI/wallet pickers only
  /// ever offer what this Razorpay account actually supports.
  Future<Map<String, dynamic>> _loadMethods() {
    return _methods ??= () async {
      // Never ask for the enabled methods before the order exists — the key
      // id comes back with it.
      if (!await _ensureOrder()) {
        throw const RazorpayCustomCheckoutException(
          'Could not reach the payment gateway. Please try again.',
        );
      }
      return _checkout.getPaymentMethods(keyId: _keyId!);
    }()
        .catchError((Object e) {
      _methods = null;
      throw e;
    });
  }

  // ---------------------------------------------------------- 2. charge

  /// Charges [method] against the order, then verifies and issues. This is
  /// the only path to a payment on this screen — every accordion funnels
  /// through it, so there is one charge path and one place that can issue.
  Future<void> _pay(Map<String, dynamic> method) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();

    if (_expired) {
      setState(() => _error =
          'This price is no longer held. Go back and search again for a '
          'fresh quote.');
      return;
    }
    if (!await _ensureOrder() || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
      _status = 'Complete the payment to continue…';
    });

    try {
      final result = await _checkout.submitPayment(
        keyId: _keyId!,
        data: {
          'amount': _orderAmountPaise ?? _amountInPaise,
          'currency': 'INR',
          'order_id': _orderId,
          'email': widget.details.proposer.email,
          'contact': widget.details.proposer.contactNumber,
          'description': '${widget.plan.planName} — Travel Insurance',
          ...method,
        },
      );
      if (!mounted) return;
      await _verifyAndIssue(result);
    } on RazorpayCustomCheckoutException catch (e) {
      // Logged as well as shown: a gateway refusal used to reach the error
      // card and nothing else, which left a failed charge looking on the
      // console exactly like a charge that simply never came back.
      debugPrint('[ins] payment failed (${e.code}): ${e.message}');
      if (!mounted) return;
      // Backing out of the SDK is not a failure worth an error card.
      if (e.message.toLowerCase().contains('cancel')) {
        setState(() => _busy = false);
        insSnack(context, 'Payment cancelled. You can try again.');
        return;
      }
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Future<void> _payWithUpiApp(UpiApp app) => _pay({
        'method': 'upi',
        '_[flow]': 'intent',
        'upi_app_package_name': app.package,
      });

  Future<void> _payWithGooglePay() async {
    if (_busy) return;
    final apps = await _upiApps;
    final gpay = apps.where((a) => a.isGooglePay).firstOrNull;
    if (!mounted) return;
    if (gpay == null) {
      insSnack(
        context,
        "Google Pay isn't installed on this device. Pay with another UPI app.",
      );
      // Open the UPI panel instead, so there is still a way to pay.
      setState(() => _open = 'upi');
      return;
    }
    await _payWithUpiApp(gpay);
  }

  // ------------------------------------------------- 3/4. verify + issue

  Future<void> _verifyAndIssue(RazorpayCustomPaymentResult payment) async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Verifying payment…';
    });

    final dio = di.sl<DioClient>().instance;

    try {
      final verify = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': payment.orderId ?? _orderId,
          'razorpay_payment_id': payment.paymentId,
          'razorpay_signature': payment.signature,
          'reference_id': _reference,
        },
      );
      if (!mounted) return;
      if (verify.data is Map && verify.data['success'] != true) {
        debugPrint('[ins] verify rejected the charge: ${verify.data}');
        setState(() {
          _busy = false;
          _error = 'We could not verify this payment. Please contact support '
              'with reference $_reference.';
        });
        return;
      }
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'We could not verify this payment. Please contact support '
            'with reference $_reference.';
      });
      return;
    }

    // ---- issue the policy; the charge has already cleared by here ----
    setState(() => _status = 'Issuing your policy…');

    final countryState = context.read<CountryBloc>().state;
    final issuer = InsPolicyIssuer(
      query: widget.query,
      details: widget.details,
      plan: widget.plan,
      tui: widget.tui,
      countries: countryState is CountryLoaded
          ? countryState.countries
          : const <CountryEntity>[],
    );

    final issued = await issuer.issue(
      gateway: 'razorpay',
      // The order's reference_id, NOT the Razorpay payment id: the backend's
      // payment guard looks up the paid transaction by the reference the
      // order was created and verified under, and answers StartPay with 402
      // "Payment not verified" when it cannot find one. Same convention the
      // transport reservation and flight StartPay calls use.
      paymentReference: _reference,
      // The gateway's own transaction id rides along separately so the
      // charge and the policy can still be reconciled.
      paymentId: payment.paymentId,
      amount: widget.amount.round(),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InsConfirmedScreen(
          plan: widget.plan,
          query: widget.query,
          details: widget.details,
          amount: widget.amount,
          paymentReference: _reference,
          paymentId: payment.paymentId,
          transactionId: issued.transactionId,
          policyNumber: issued.policyNumber,
          // A policy that has not come back yet is never shown as a failed
          // payment — the money is taken and support can reconcile from the
          // reference.
          issuePending: !issued.isIssued,
          issueMessage: issued.message,
        ),
      ),
    );
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _header(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.only(bottom: context.h(28)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _summaryCollapsed(context),
                          if (_error != null) ...[
                            SizedBox(height: context.h(14)),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: context.w(16)),
                              child: InsErrorCard(message: _error!),
                            ),
                          ],
                          SizedBox(height: context.h(32)),
                          _sectionLabel(context, 'Suggested options'),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(16),
                            ),
                            child: Column(children: _suggested(context)),
                          ),
                          SizedBox(height: context.h(14)),
                          _sectionLabel(context, 'Other Payment Options'),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(16),
                            ),
                            child: Column(children: _otherMethods(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // The expanded summary is an overlay: it dims the page, drops
              // the full breakdown down from the top and floats its dismiss
              // cross outside the panel's bottom edge.
              if (_summaryOpen) ..._summaryOverlay(context),

              if (_busy) _processingOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(8),
        context.w(16),
        context.h(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _busy ? null : () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: EdgeInsets.all(context.w(4)),
              child: Icon(Icons.arrow_back_rounded,
                  size: context.w(21), color: InsTokens.navy),
            ),
          ),
          SizedBox(width: context.w(14)),
          Expanded(
            child: Text(
              'Payment',
              style: TextStyle(
                fontSize: context.fs(20),
                fontWeight: FontWeight.w600,
                color: InsTokens.navy,
              ),
            ),
          ),
          // The quote is only held for so long; the design counts it down.
          Icon(Icons.timer_rounded,
              size: context.w(14),
              color: _expired ? InsTokens.errorFg : InsTokens.blue),
          SizedBox(width: context.w(4)),
          Text(
            _expired ? 'Expired' : _clock,
            style: TextStyle(
              fontSize: context.fs(12),
              fontWeight: FontWeight.w500,
              color: _expired ? InsTokens.errorFg : InsTokens.blue,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- summary

  /// The compact summary that sits inline on the page: total, plan and who
  /// is covered. Tapping the chevron opens [_summaryOverlay].
  Widget _summaryCollapsed(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(32),
        context.w(16),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _summaryOpen = true),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Due',
                    style: TextStyle(
                      fontSize: context.fs(20),
                      fontWeight: FontWeight.w700,
                      color: InsTokens.navy,
                    ),
                  ),
                ),
                Text(
                  InsTokens.rupees(widget.amount),
                  style: TextStyle(
                    fontSize: context.fs(20),
                    fontWeight: FontWeight.w700,
                    color: InsTokens.navy,
                  ),
                ),
                SizedBox(width: context.w(8)),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: context.w(22), color: InsTokens.blue),
              ],
            ),
          ),
          SizedBox(height: context.h(22)),
          _planLine(context),
          SizedBox(height: context.h(12)),
          const Divider(height: 1, color: InsTokens.line),
          SizedBox(height: context.h(12)),
          Text(
            _travellerSummary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(10),
              fontWeight: FontWeight.w600,
              color: InsTokens.subGrey,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _summaryOverlay(BuildContext context) {
    return [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _summaryOpen = false),
          child: ColoredBox(color: Colors.black.withOpacity(0.35)),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(context.r(22)),
              ),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF2FAFE), Color(0xFFCFECFB)],
                  ),
                ),
                child: Column(
                  children: [
                    _header(context),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.w(16),
                        context.h(6),
                        context.w(16),
                        context.h(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _summaryOpen = false),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Total Due',
                                    style: TextStyle(
                                      fontSize: context.fs(20),
                                      fontWeight: FontWeight.w700,
                                      color: InsTokens.navy,
                                    ),
                                  ),
                                ),
                                Text(
                                  InsTokens.rupees(widget.amount),
                                  style: TextStyle(
                                    fontSize: context.fs(20),
                                    fontWeight: FontWeight.w700,
                                    color: InsTokens.navy,
                                  ),
                                ),
                                SizedBox(width: context.w(8)),
                                Icon(Icons.keyboard_arrow_up_rounded,
                                    size: context.w(24), color: InsTokens.blue),
                              ],
                            ),
                          ),
                          SizedBox(height: context.h(20)),
                          _premiumLine(context),
                          SizedBox(height: context.h(16)),
                          _planLine(context),
                          SizedBox(height: context.h(12)),
                          const Divider(height: 1, color: Color(0x33000000)),
                          SizedBox(height: context.h(12)),
                          Text(
                            _travellerSummary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(13),
                              fontWeight: FontWeight.w600,
                              color: InsTokens.navy,
                            ),
                          ),
                          SizedBox(height: context.h(3)),
                          Text(
                            '${widget.details.proposer.email}  |  '
                            '${widget.details.proposer.dialCode} '
                            '${widget.details.proposer.contactNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(12),
                              color: InsTokens.subGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.h(14)),
            // Close — floats outside the drawer, bottom centre.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _summaryOpen = false),
              child: Container(
                width: context.w(40),
                height: context.w(40),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    size: context.w(21), color: InsTokens.navy),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// `Insurance Premium ·········· ₹ 6,784`
  Widget _premiumLine(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Insurance Premium',
          style: TextStyle(
            fontSize: context.fs(14),
            color: InsTokens.subGrey,
          ),
        ),
        SizedBox(width: context.w(8)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: context.h(4)),
            child: const _DottedLeader(),
          ),
        ),
        SizedBox(width: context.w(8)),
        Text(
          InsTokens.rupees(widget.amount),
          style: TextStyle(
            fontSize: context.fs(14),
            fontWeight: FontWeight.w500,
            color: InsTokens.navy,
          ),
        ),
      ],
    );
  }

  Widget _planLine(BuildContext context) {
    final end = widget.query.resolvedEndDate ?? widget.query.startDate;
    // International whenever any destination differs from the country the
    // trip starts in — read off the trip, not assumed.
    final international = widget.query.destinations
        .any((d) => d.code != widget.query.fromCountry.code);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsProviderLogo(
          provider: widget.plan.provider,
          logoUrl: widget.plan.logoUrl,
          width: context.w(56),
          height: context.h(40),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.plan.planName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fs(14),
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: InsTokens.navy,
                ),
              ),
              SizedBox(height: context.h(3)),
              Text(
                '${InsTokens.shortDate(widget.query.startDate)} - '
                '${InsTokens.shortDate(end)} | '
                '${international ? 'International' : 'Domestic'} Trip',
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w400,
                  color: InsTokens.subGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _travellerSummary {
    final lead = widget.details.lead;
    final others = widget.details.travellers.length - 1;
    final age = _ageOf(lead.dob);
    return '${lead.fullName.toUpperCase()} (${lead.genderCode})'
        '${age == null ? '' : ' ${age}yrs'}'
        '${others > 0 ? ', +$others traveller${others == 1 ? '' : 's'}' : ''}';
  }

  static int? _ageOf(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }

  // ----------------------------------------------------------- methods

  /// Offer copy. Deliberately factual: the backend quotes no card-, bank- or
  /// UPI-specific discount for insurance, so no rupee figure is claimed here
  /// that the charge would not honour.
  static const _emiNote =
      'Spread the premium over monthly instalments on an eligible credit card.';
  static const _upiNote =
      'Pay by UPI and the money leaves your bank instantly — no card details '
      'to enter.';

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        0,
        context.w(16),
        context.h(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(17),
          fontWeight: FontWeight.w600,
          color: InsTokens.navy,
        ),
      ),
    );
  }

  /// The green note that sits above a suggested method, as the design groups
  /// them.
  Widget _offerStrip(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(8)),
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9F3),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded,
              size: context.w(18), color: const Color(0xFF16A34A)),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.fs(13),
                height: 1.35,
                color: InsTokens.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The one-tap Google Pay row. A shortcut into the same UPI intent charge
  /// the UPI panel offers, so it is a plain row rather than an accordion.
  Widget _googlePayRow(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: CheckoutColors.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : _payWithGooglePay,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(14),
          ),
          child: Row(
            children: [
              const CheckoutIcon('assets/NewIcons/gpay.png'),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GooglePay',
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                        color: CheckoutColors.ink,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      'Pay with GooglePay',
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: CheckoutColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: context.w(22), color: CheckoutColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// Suggested methods, then the rest — each one expanding in place, the way
  /// the wallet top-up checkout does.
  List<Widget> _suggested(BuildContext context) {
    return [
      _offerStrip(context, _emiNote),
      CheckoutAccordion(
        title: 'EMI',
        subtitle: 'Credit/Debit Card & Cardless EMI available',
        leading: const CheckoutIcon('assets/NewIcons/credit.png'),
        expanded: _open == 'emi',
        onTap: () => _toggle('emi'),
        // Built only while open so the enabled-methods lookup is not fired
        // for a panel the traveller never opened.
        child: _open == 'emi'
            ? EmiSection(
                amount: widget.amount,
                busy: _busy,
                methods: _loadMethods(),
                onPay: (months, card) => _pay({
                  'method': 'emi',
                  'emi_duration': months,
                  'card': card,
                }),
              )
            : const SizedBox.shrink(),
      ),
      _offerStrip(context, _upiNote),
      _googlePayRow(context),
      CheckoutAccordion(
        title: 'UPI Options',
        subtitle: 'Pay Directly From Your Bank Account',
        badge: 'INSTANT',
        leading: const CheckoutIcon('assets/NewIcons/upi.png'),
        expanded: _open == 'upi',
        onTap: () => _toggle('upi'),
        child: UpiSection(
          amount: widget.amount,
          busy: _busy,
          apps: _upiApps,
          onPayWithApp: _payWithUpiApp,
          onPayWithVpa: (vpa) =>
              _pay({'method': 'upi', '_[flow]': 'collect', 'vpa': vpa}),
        ),
      ),
    ];
  }

  List<Widget> _otherMethods(BuildContext context) {
    return [
      CheckoutAccordion(
        title: 'Credit & Debit Cards',
        subtitle: 'Visa, Mastercard, Amex, Rupay and more',
        leading: const CheckoutIcon('assets/NewIcons/credit.png'),
        expanded: _open == 'card',
        onTap: () => _toggle('card'),
        child: CardForm(
          payLabel: 'Pay ${formatInr(widget.amount)}',
          busy: _busy,
          onSubmit: (card) => _pay({'method': 'card', 'card': card}),
        ),
      ),
      CheckoutAccordion(
        title: 'Net Banking',
        subtitle: 'All major banks available',
        leading: const CheckoutIcon('assets/NewIcons/net_banking.png'),
        expanded: _open == 'netbanking',
        onTap: () => _toggle('netbanking'),
        child: _open == 'netbanking'
            ? NetbankingSection(
                amount: widget.amount,
                busy: _busy,
                methods: _loadMethods(),
                onPay: (bank) => _pay({'method': 'netbanking', 'bank': bank}),
              )
            : null,
      ),
      CheckoutAccordion(
        title: 'Pay Later',
        subtitle: 'LazyPay, Simpl & more',
        leading: const CheckoutIcon('assets/NewIcons/pay_later.png'),
        expanded: _open == 'paylater',
        onTap: () => _toggle('paylater'),
        child: _open == 'paylater'
            ? PayLaterSection(
                amount: widget.amount,
                busy: _busy,
                methods: _loadMethods(),
                onPay: (provider) =>
                    _pay({'method': 'paylater', 'provider': provider}),
              )
            : null,
      ),
      CheckoutAccordion(
        title: 'Gift Cards & e-wallets',
        subtitle: 'Paytm, PhonePe, Amazon Pay & more',
        leading: const CheckoutIcon('assets/NewIcons/wallet.png'),
        expanded: _open == 'wallet',
        onTap: () => _toggle('wallet'),
        child: _open == 'wallet'
            ? WalletsSection(
                amount: widget.amount,
                busy: _busy,
                methods: _loadMethods(),
                onPay: (wallet) => _pay({'method': 'wallet', 'wallet': wallet}),
              )
            : null,
      ),
    ];
  }

  Widget _processingOverlay(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.w(40)),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(24),
              vertical: context.h(26),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: InsTokens.blue),
                SizedBox(height: context.h(18)),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(14),
                    color: InsTokens.navy,
                  ),
                ),
                SizedBox(height: context.h(6)),
                Text(
                  'Do not close this screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: InsTokens.subGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dotted leader between a label and its amount, as the design draws it.
class _DottedLeader extends StatelessWidget {
  const _DottedLeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 2.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count < 0 ? 0 : count,
            (_) => const SizedBox(
              width: dash,
              height: 1,
              child: ColoredBox(color: Color(0xFFBFC8D4)),
            ),
          ),
        );
      },
    );
  }
}
