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
import '../../../flight_payment/data/razorpay_custom_checkout_service.dart';
import '../../../flight_payment/presentation/screen/ak_custom_checkout_args.dart';
import '../../../flight_payment/presentation/screen/ak_unified_checkout_screen.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../service/ins_policy_issuer.dart';
import '../state/ins_booking_details.dart';
import '../state/ins_search_query.dart';
import '../tokens/ins_tokens.dart';
import '../widgets/ins_common.dart';
import '../widgets/ins_fare_sheet.dart';
import '../widgets/ins_plan_card.dart';
import 'ins_confirmed_screen.dart';

/// "Payment" — Figma `Payment option INSURANCE 1` and `… 2`.
///
/// The money runs on the app's own Razorpay Custom Checkout stack, the same
/// one the wallet top-up and the holiday flow use:
///
///   1. `Urls.razorpayCreateOrder` mints an order (`transaction_type:
///      insurance`)
///   2. [AkUnifiedCheckoutScreen] collects the method and charges it — this
///      is the shared custom checkout, so UPI/GPay/cards/net banking/
///      wallets all behave exactly as they do in the wallet section
///   3. `Urls.razorpayVerify` checks the signature server-side
///   4. **StartPay** issues the real policy against the agent balance
///
/// Step 4 only ever runs after a cleared charge, which is the order the
/// previous payment screen used — the policy is never issued on an
/// unverified payment.
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
  bool _busy = false;
  String _status = '';
  String? _error;

  String? _orderId;
  String? _keyId;
  bool _summaryOpen = true;

  /// How long the quoted premium is held before it has to be re-priced.
  /// The design shows this counting down beside the title.
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
          // Tells the backend's reconciliation what the charge is for, the
          // same value the previous insurance payment screen sent.
          'transaction_type': 'insurance',
          if (userId != null) 'user_id': userId,
        },
      );

      final orderId = res.data['order_id'] as String?;
      final keyId = res.data['key_id'] as String?;
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

  // ---------------------------------------------------------- 2. checkout

  Future<void> _pay() async {
    if (_busy) return;
    if (_expired) {
      setState(() => _error =
          'This price is no longer held. Go back and search again for a '
          'fresh quote.');
      return;
    }
    if (!await _ensureOrder() || !mounted) return;

    final lead = widget.details.lead;
    final result =
        await Navigator.of(context).push<RazorpayCustomPaymentResult>(
      MaterialPageRoute(
        builder: (_) => AkUnifiedCheckoutScreen(
          args: AkCustomCheckoutArgs(
            keyId: _keyId!,
            orderId: _orderId!,
            amountInInr: widget.amount,
            name: lead.fullName,
            email: widget.details.proposer.email,
            contact: widget.details.proposer.contactNumber,
            description: '${widget.plan.planName} — Travel Insurance',
          ),
        ),
      ),
    );

    // Backing out of the method screen is not a failure.
    if (result == null || !mounted) return;
    await _verifyAndIssue(result);
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
      paymentReference: payment.paymentId,
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
    if (_busy) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: InsLoading(message: _status)),
      );
    }

    return Scaffold(
      backgroundColor: InsTokens.pageBg,
      appBar: insAppBar(
        context,
        title: 'Payment',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.w(16)),
            child: Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: context.w(19),
                    color: _expired ? InsTokens.errorFg : InsTokens.blue),
                SizedBox(width: context.w(6)),
                Text(
                  _expired ? 'Expired' : _clock,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w500,
                    color: _expired ? InsTokens.errorFg : InsTokens.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: context.h(24)),
        children: [
          _totalCard(context),
          SizedBox(height: context.h(18)),
          if (_error != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(14)),
              child: InsErrorCard(message: _error!),
            ),
            SizedBox(height: context.h(16)),
          ],
          _sectionLabel(context, 'Suggested options'),
          _group(context, [
            _offerStrip(
              context,
              'Pay by UPI and the money leaves your bank instantly — no '
              'card details to enter.',
            ),
            _method(
              context,
              asset: InsTokens.iconGpay,
              title: 'GooglePay',
              subtitle: 'Pay with GooglePay',
            ),
            _divider(context),
            _method(
              context,
              asset: InsTokens.iconUpi,
              title: 'UPI Options',
              subtitle: 'Pay Directly From Your Bank Account',
            ),
          ]),
          SizedBox(height: context.h(18)),
          _sectionLabel(context, 'Other Payment Options'),
          _group(context, [
            _method(
              context,
              asset: InsTokens.iconCard,
              title: 'Credit & Debit Cards',
              subtitle: 'Visa, Mastercard, Amex, Rupay and more',
            ),
          ]),
          SizedBox(height: context.h(14)),
          _group(context, [
            _method(
              context,
              asset: InsTokens.iconNetBanking,
              title: 'Net Banking',
              subtitle: '40+ Banks available',
            ),
            _divider(context),
            _method(
              context,
              asset: InsTokens.iconPayLater,
              title: 'Pay Later',
              subtitle: 'Lazypay, Amazon',
            ),
            _divider(context),
            _method(
              context,
              asset: InsTokens.iconWallet,
              title: 'Gift Cards & e-wallets',
              subtitle: 'WNT Gift cards & Amazon Pay',
            ),
          ]),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- pieces

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        0,
        context.w(16),
        context.h(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.fs(17),
          fontWeight: FontWeight.w500,
          color: InsTokens.navy,
        ),
      ),
    );
  }

  Widget _group(BuildContext context, List<Widget> children) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(14)),
      child: Container(
        decoration: insCard(context, border: true, shadow: false),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _divider(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: context.w(14)),
        child: const Divider(height: 1, color: InsTokens.line),
      );

  /// The green strip above a method group. Shows a real, factual line about
  /// the method rather than a discount the backend has not quoted.
  Widget _offerStrip(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      color: InsTokens.offerBg,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded,
              size: context.w(19), color: InsTokens.offerIcon),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.fs(14),
                height: 1.35,
                color: InsTokens.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One tappable payment method. Every row opens the same shared custom
  /// checkout — it carries the real method UI (and knows which UPI apps are
  /// actually installed), so routing them all there keeps one charge path.
  Widget _method(
    BuildContext context, {
    required String asset,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: _pay,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(14),
        ),
        child: Row(
          children: [
            Image.asset(
              asset,
              width: context.w(34),
              height: context.w(34),
              errorBuilder: (_, __, ___) => Icon(
                Icons.payments_rounded,
                size: context.w(30),
                color: InsTokens.blue,
              ),
            ),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fs(17),
                      fontWeight: FontWeight.w600,
                      color: InsTokens.navy,
                    ),
                  ),
                  SizedBox(height: context.h(3)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.fs(14),
                      color: InsTokens.subGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: context.w(22), color: InsTokens.blue),
          ],
        ),
      ),
    );
  }

  Widget _totalCard(BuildContext context) {
    final lead = widget.details.lead;
    final others = widget.details.travellers.length - 1;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(10),
        context.w(16),
        context.h(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _summaryOpen = !_summaryOpen),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Due',
                    style: TextStyle(
                      fontSize: context.fs(24),
                      fontWeight: FontWeight.w600,
                      color: InsTokens.navy,
                    ),
                  ),
                ),
                Text(
                  InsTokens.rupees(widget.amount),
                  style: TextStyle(
                    fontSize: context.fs(26),
                    fontWeight: FontWeight.w700,
                    color: InsTokens.navy,
                  ),
                ),
                SizedBox(width: context.w(6)),
                Icon(
                  _summaryOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: context.w(24),
                  color: InsTokens.blue,
                ),
              ],
            ),
          ),
          if (_summaryOpen) ...[
            SizedBox(height: context.h(18)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InsProviderLogo(
                  provider: widget.plan.provider,
                  logoUrl: widget.plan.logoUrl,
                  width: 60,
                  height: 46,
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plan.planName,
                        style: TextStyle(
                          fontSize: context.fs(16),
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: InsTokens.navy,
                        ),
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        '${InsTokens.shortDate(widget.query.startDate)} - '
                        '${InsTokens.shortDate(widget.query.resolvedEndDate ?? widget.query.startDate)}'
                        '  |  ${widget.query.policyType.label} Trip',
                        style: TextStyle(
                          fontSize: context.fs(13.5),
                          color: InsTokens.subGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(14)),
            const Divider(height: 1, color: InsTokens.line),
            SizedBox(height: context.h(12)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${lead.fullName.toUpperCase()} '
                    '(${lead.genderCode})'
                    '${others > 0 ? ', +$others traveller${others == 1 ? '' : 's'}' : ''}',
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: context.fs(13.5),
                      color: InsTokens.subGrey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => InsFareSheet.show(
                    context,
                    baseFare: widget.amount,
                    taxes: 0,
                    travellers: widget.details.travellers.length,
                    planName: widget.plan.planName,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        'Fare breakup',
                        style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w500,
                          color: InsTokens.blue,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: context.w(18), color: InsTokens.blue),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
