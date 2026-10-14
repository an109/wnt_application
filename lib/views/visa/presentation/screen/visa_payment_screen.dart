import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/common_widgets/app_loader.dart';
import 'package:wander_nova/core/constants/urls.dart';
import 'package:wander_nova/core/network/dio_client.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';

import '../../../flight_payment/data/razorpay_custom_checkout_service.dart';
import '../../../wallet/data/data_source/wallet_api_service.dart';
import '../../../wallet/wallet/screen/checkout/card_form.dart';
import '../../../wallet/wallet/screen/checkout/checkout_ui.dart';
import '../../../wallet/wallet/screen/checkout/method_sections.dart';
import '../../../wallet/wallet/screen/checkout/upi_section.dart';
import 'package:wander_nova/common_widgets/currency_scope.dart';
import '../../data/visa_submit_service.dart';

/// Payment page of the visa application — the same layout and methods as
/// [AkHotelPaymentScreen] / the flight payment screen (Total Due, My Wallet,
/// Google Pay, UPI, cards, net banking, EMI, wallets & Pay Later).
///
/// The application already exists; this screen charges it and then calls
/// complete-payment, which re-checks the Razorpay signature or the wallet
/// debit server-side. Pops `true` once the application is marked paid.
class VisaPaymentScreen extends StatefulWidget {
  final int applicationId;
  final double amountInr;
  final String title;
  final String subtitle;
  final String image;
  final String travellersSummary;
  final String email;
  final String phone;

  const VisaPaymentScreen({
    super.key,
    required this.applicationId,
    required this.amountInr,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.travellersSummary,
    required this.email,
    required this.phone,
  });

  @override
  State<VisaPaymentScreen> createState() => _VisaPaymentScreenState();
}

class _VisaPaymentScreenState extends State<VisaPaymentScreen> {
  static const _pri = AppColors.AppBlue;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);
  static const _offer = Color(0xFF16A34A);

  final _visa = VisaSubmitService();
  final _rzService = RazorpayCustomCheckoutService();

  bool _processing = false;
  String _statusMessage = '';
  String? _errorMessage;
  String? _selectedTileId;
  String? _open;

  String? _razorpayOrderId;
  String? _razorpayKeyId;
  late final Future<List<UpiApp>> _upiApps = _rzService.getUpiApps().catchError((_) => <UpiApp>[]);
  Future<Map<String, dynamic>>? _methods;

  /// Set once the wallet has been charged, so it is never charged twice.
  String? _walletDebitRef;

  /// Same 15-minute UI guard as the flight and hotel payment pages.
  static const _holdDuration = Duration(minutes: 15);
  Timer? _holdTimer;
  Duration _timeLeft = _holdDuration;
  bool get _expired => _timeLeft <= Duration.zero;
  String get _minutes => _timeLeft.inMinutes.toString().padLeft(2, '0');
  String get _seconds => (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

  String get _bookingRef => 'visa_${widget.applicationId}';

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

  // ==================== WALLET ====================

  Future<void> _payWithWallet() async {
    if (_expired || _processing) return;
    setState(() {
      _selectedTileId = 'wallet';
      _errorMessage = null;
    });
    if (_walletDebitRef != null) {
      await _complete(mode: 'wallet', reference: _walletDebitRef!);
      return;
    }
    setState(() {
      _processing = true;
      _statusMessage = 'Checking wallet balance...';
    });
    try {
      final response = await sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;
      if (!mounted) return;
      if (balance < widget.amountInr) {
        setState(() {
          _processing = false;
          _errorMessage = 'Insufficient wallet balance (₹${balance.toStringAsFixed(2)} available)';
        });
        return;
      }
      setState(() => _statusMessage = 'Paying from your wallet...');
      final debit = await sl<WalletApiService>().payBooking(
        amount: widget.amountInr.ceilToDouble(),
        bookingType: 'visa',
        bookingRef: _bookingRef,
        description: 'Visa: ${widget.title}',
      );
      if (!mounted) return;
      if (!debit.success || debit.reference == null) {
        setState(() {
          _processing = false;
          _errorMessage = debit.error ?? 'Wallet payment failed. Please try again.';
        });
        return;
      }
      _walletDebitRef = debit.reference;
      await _complete(mode: 'wallet', reference: debit.reference!);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Could not fetch wallet balance. Please try again.';
      });
    }
  }

  // ==================== RAZORPAY ====================

  /// One order per payment attempt, reused by every method.
  Future<bool> _ensureRazorpayOrder() async {
    if (_razorpayOrderId != null && _razorpayKeyId != null) return true;
    setState(() {
      _processing = true;
      _errorMessage = null;
      _statusMessage = 'Preparing payment...';
    });
    try {
      final order = await _visa.createRazorpayOrder(widget.amountInr, widget.applicationId);
      if (!mounted) return false;
      setState(() {
        _processing = false;
        _razorpayOrderId = order['order_id'].toString();
        _razorpayKeyId = order['key_id'].toString();
      });
      return true;
    } on VisaSubmitException catch (e) {
      if (!mounted) return false;
      setState(() {
        _processing = false;
        _errorMessage = e.message;
      });
      return false;
    }
  }

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

  Future<Map<String, dynamic>> _loadMethods() {
    return _methods ??= () async {
      if (!await _ensureRazorpayOrder()) throw Exception('order');
      return _rzService.getPaymentMethods(keyId: _razorpayKeyId!);
    }()
        .catchError((Object e) {
      _methods = null;
      throw e;
    });
  }

  Future<void> _payWithMethod(Map<String, dynamic> method) async {
    if (_expired || _processing) return;
    FocusScope.of(context).unfocus();
    if (!await _ensureRazorpayOrder() || !mounted) return;
    setState(() {
      _processing = true;
      _statusMessage = 'Complete the payment to continue...';
      _errorMessage = null;
    });
    try {
      final result = await _rzService.submitPayment(
        keyId: _razorpayKeyId!,
        data: {
          'amount': (widget.amountInr * 100).round(),
          'currency': 'INR',
          'order_id': _razorpayOrderId,
          'email': widget.email,
          'contact': widget.phone,
          'description': 'Visa: ${widget.title}',
          ...method,
        },
      );
      await _verifyAndComplete(result);
    } on RazorpayCustomCheckoutException catch (e) {
      if (!mounted) return;
      if (e.message.toLowerCase().contains('cancel')) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment cancelled. You can try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        setState(() {
          _processing = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  Future<void> _payWithGooglePay() async {
    if (_expired || _processing) return;
    final apps = await _upiApps;
    final gpay = apps.where((a) => a.isGooglePay).firstOrNull;
    if (!mounted) return;
    if (gpay == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Google Pay isn't installed. Try another method."),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _open = 'upi');
      return;
    }
    await _payWithMethod({'method': 'upi', '_[flow]': 'intent', 'upi_app_package_name': gpay.package});
  }

  Future<void> _verifyAndComplete(RazorpayCustomPaymentResult result) async {
    setState(() {
      _processing = true;
      _statusMessage = 'Verifying payment...';
    });
    // Marks the Razorpay transaction paid for reconciliation, as hotels and
    // flights do. complete-payment checks the signature again regardless.
    try {
      await sl<DioClient>().instance.post(Urls.razorpayVerify, data: {
        'razorpay_order_id': result.orderId ?? _razorpayOrderId,
        'razorpay_payment_id': result.paymentId,
        'razorpay_signature': result.signature,
        'reference_id': _bookingRef,
      });
    } on DioException catch (_) {}
    await _complete(
      mode: 'razorpay',
      reference: result.paymentId,
      orderId: result.orderId ?? _razorpayOrderId,
      signature: result.signature,
    );
  }

  Future<void> _complete({
    required String mode,
    required String reference,
    String? orderId,
    String? signature,
  }) async {
    if (!mounted) return;
    setState(() {
      _processing = true;
      _statusMessage = 'Submitting your application...';
    });
    try {
      await _visa.completePayment(
        applicationId: widget.applicationId,
        email: widget.email,
        reference: reference,
        mode: mode,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
      );
      if (mounted) Navigator.pop(context, true);
    } on VisaSubmitException catch (_) {
      if (!mounted) return;
      // Money has moved: never retry silently, show the reference instead.
      setState(() {
        _processing = false;
        _errorMessage = 'Payment received, but the application could not be updated yet. '
            'Please contact support with reference $reference — do not pay again.';
      });
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _header(context),
              const Divider(height: 1, color: _stroke),
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
                      if (_processing)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: context.h(48)),
                          child: AppLoadingView(message: _statusMessage),
                        )
                      else ...[
                        if (_errorMessage != null) ...[
                          _errorBanner(context, _errorMessage!),
                          SizedBox(height: context.h(16)),
                        ],
                        if (_expired) ...[
                          _errorBanner(context,
                              'This payment session has timed out. Please go back and start the payment again.'),
                          SizedBox(height: context.h(16)),
                        ],
                        if (sl<PreferencesManager>().isLoggedIn())
                          _optionCard(context, children: [
                            _optionRow(
                              context,
                              tileId: 'wallet',
                              onTap: _payWithWallet,
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: _offer,
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
                          child: _open == 'upi'
                              ? UpiSection(
                                  amount: widget.amountInr,
                                  busy: _processing,
                                  apps: _upiApps,
                                  onPayWithApp: (app) => _payWithMethod(
                                      {'method': 'upi', '_[flow]': 'intent', 'upi_app_package_name': app.package}),
                                  onPayWithVpa: (vpa) =>
                                      _payWithMethod({'method': 'upi', '_[flow]': 'collect', 'vpa': vpa}),
                                )
                              : const SizedBox.shrink(),
                        ),
                        CheckoutAccordion(
                          title: 'Credit / Debit Card',
                          subtitle: 'Visa, Mastercard, RuPay, Amex & more',
                          leading: const CheckoutIcon('assets/NewIcons/credit.png'),
                          expanded: _open == 'card',
                          onTap: () => _toggle('card'),
                          child: _open == 'card'
                              ? CardForm(
                                  payLabel: 'Pay ${formatInr(widget.amountInr)}',
                                  busy: _processing,
                                  onSubmit: (card) => _payWithMethod({'method': 'card', 'card': card}),
                                )
                              : const SizedBox.shrink(),
                        ),
                        CheckoutAccordion(
                          title: 'Net Banking',
                          subtitle: 'All major banks available',
                          leading: const CheckoutIcon('assets/NewIcons/net_banking.png'),
                          expanded: _open == 'netbanking',
                          onTap: () => _toggle('netbanking'),
                          child: _open == 'netbanking'
                              ? NetbankingSection(
                                  amount: widget.amountInr,
                                  busy: _processing,
                                  methods: _loadMethods(),
                                  onPay: (bank) => _payWithMethod({'method': 'netbanking', 'bank': bank}),
                                )
                              : const SizedBox.shrink(),
                        ),
                        CheckoutAccordion(
                          title: 'EMI',
                          subtitle: 'Easy monthly instalments on credit cards',
                          leading: _emiIcon(context),
                          expanded: _open == 'emi',
                          onTap: () => _toggle('emi'),
                          child: _open == 'emi'
                              ? EmiSection(
                                  amount: widget.amountInr,
                                  busy: _processing,
                                  methods: _loadMethods(),
                                  onPay: (months, card) =>
                                      _payWithMethod({'method': 'emi', 'emi_duration': months, 'card': card}),
                                )
                              : const SizedBox.shrink(),
                        ),
                        CheckoutAccordion(
                          title: 'Wallets & Pay Later',
                          subtitle: 'Paytm, PhonePe, Amazon Pay · LazyPay, Simpl & more',
                          leading: const CheckoutIcon('assets/NewIcons/wallet.png'),
                          expanded: _open == 'wallet',
                          onTap: () => _toggle('wallet'),
                          child: _open == 'wallet'
                              ? WalletsPayLaterSection(
                                  amount: widget.amountInr,
                                  busy: _processing,
                                  methods: _loadMethods(),
                                  onPayWallet: (w) => _payWithMethod({'method': 'wallet', 'wallet': w}),
                                  onPayLater: (p) => _payWithMethod({'method': 'paylater', 'provider': p}),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
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

  Widget _header(BuildContext context) {
    final color = _expired ? const Color(0xffB42318) : _pri;
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
            child: Text('Payment',
                style: TextStyle(fontSize: context.fs(20), fontWeight: FontWeight.w600, color: Colors.black)),
          ),
          Icon(Icons.timer, size: context.w(16), color: color),
          SizedBox(width: context.w(4)),
          Text('$_minutes:$_seconds',
              style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _totalDue(BuildContext context) {
    final hint = context.moneyHint(widget.amountInr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _totalDueRow(context),
        if (hint.isNotEmpty)
          Text('$hint · charged in INR', style: TextStyle(fontSize: context.fs(12), color: _muted)),
      ],
    );
  }

  Widget _totalDueRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text('Total Due',
              style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.w700, color: Colors.black)),
        ),
        SizedBox(width: context.w(8)),
        Text(formatInr(widget.amountInr),
            style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.w800, color: Colors.black)),
      ],
    );
  }

  Widget _summaryCard(BuildContext context) {
    final placeholder = Container(
      width: context.w(44),
      height: context.w(44),
      color: const Color(0xFFF1F5F9),
      child: Icon(Icons.public, size: context.w(20), color: _muted),
    );
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
                child: widget.image.isEmpty
                    ? placeholder
                    : Image.network(
                        widget.image,
                        width: context.w(44),
                        height: context.w(44),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => placeholder,
                      ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.fs(13.5), fontWeight: FontWeight.w700, color: _ink)),
                    if (widget.subtitle.isNotEmpty) ...[
                      SizedBox(height: context.h(3)),
                      Text(widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: context.fs(11), color: _muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.travellersSummary.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(10)),
              child: const Divider(height: 1, color: _stroke),
            ),
            Text(widget.travellersSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.fs(11.5), color: _muted)),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) =>
      Text(text, style: TextStyle(fontSize: context.fs(16), fontWeight: FontWeight.w600, color: Colors.black));

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

  Widget _optionRow(
    BuildContext context, {
    required String tileId,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedTileId == tileId;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (_expired || _processing) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(14)),
        color: selected ? _pri.withValues(alpha: 0.05) : Colors.white,
        child: Row(
          children: [
            Icon(icon, size: context.w(22), color: iconColor),
            SizedBox(width: context.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: _ink)),
                  SizedBox(height: context.h(3)),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.fs(12), color: _muted)),
                ],
              ),
            ),
            SizedBox(width: context.w(8)),
            Icon(selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                size: context.w(22), color: _pri),
          ],
        ),
      ),
    );
  }

  Widget _emiIcon(BuildContext context) => Container(
        width: context.w(34),
        height: context.w(34),
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            const CheckoutIcon('assets/NewIcons/gpay.png'),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Google Pay',
                    style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: _ink)),
                SizedBox(height: context.h(2)),
                Text('Pay instantly from the Google Pay app',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.fs(12), color: _muted)),
              ]),
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
          Expanded(child: Text(message, style: TextStyle(color: const Color(0xffB42318), fontSize: context.fs(12)))),
        ],
      ),
    );
  }
}
