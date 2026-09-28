import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/constants/urls.dart';
import 'package:wander_nova/core/network/dio_client.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/core/utils/storage/shared_preference.dart';
import 'package:wander_nova/injection_container.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';

import 'checkout/card_form.dart';
import 'checkout/checkout_ui.dart';
import 'checkout/method_sections.dart';
import 'checkout/qr_pay_panel.dart';
import 'checkout/upi_section.dart';

/// Full-screen wallet top-up checkout (MakeMyTrip-style accordion): UPI
/// (apps / UPI ID / QR), cards, net banking, EMI and wallets, all paid
/// in-page through Razorpay Custom Checkout (native SDK on Android and iOS).
///
/// Flow (same as the web app):
///   /wallet/add-money/ (creates the WalletTransaction + Razorpay order)
///   → Razorpay charges the order (UPI intent / card / bank / wallet)
///   → /payments/razorpay/verify/ → /wallet/verify-payment/ (credit)
/// QR payments skip the order: create-qr → poll qr-status →
///   /wallet/verify-payment/ with the razorpay_payment_id.
///
/// Pops `true` only once the wallet backend confirms the credit.
class WalletTopUpCheckoutScreen extends StatefulWidget {
  /// Top-up amount in INR.
  final double amount;

  const WalletTopUpCheckoutScreen({super.key, required this.amount});

  @override
  State<WalletTopUpCheckoutScreen> createState() =>
      _WalletTopUpCheckoutScreenState();
}

class _WalletTopUpCheckoutScreenState extends State<WalletTopUpCheckoutScreen> {
  final _service = RazorpayCustomCheckoutService();

  bool _processing = false;
  String _statusMessage = '';
  String? _errorMessage;
  String? _open = 'upi'; // expanded accordion section

  // Created once per checkout by /wallet/add-money/ and reused across
  // attempts/methods — one order, one payment.
  String? _orderId;
  String? _keyId;
  String? _reference;

  // Razorpay requires a contact number and email on every payment. Taken from
  // the profile, or asked for once when the profile doesn't have them (e.g.
  // Google/Apple sign-in accounts without a phone number).
  String _contact = '';
  String _email = '';

  late final Future<List<UpiApp>> _upiApps = _service.getUpiApps().catchError(
    (_) => <UpiApp>[],
  );
  Future<Map<String, dynamic>>? _methods;

  double get _amount => double.parse(widget.amount.toStringAsFixed(2));
  bool get _busy => _processing;

  // ==================== ORDER / DETAILS ====================

  Future<bool> _ensureWalletOrder({bool overlay = true}) async {
    if (_orderId != null && _keyId != null && _reference != null) return true;

    if (overlay) {
      setState(() {
        _processing = true;
        _errorMessage = null;
        _statusMessage = 'Preparing payment...';
      });
    }

    String? error;
    try {
      final response = await sl<DioClient>().instance.post(
        Urls.walletAddMoney,
        data: {
          'amount': _amount,
          'payment_method': 'razorpay',
          'base_url': 'https://thewandernova.com/',
          'currency': 'INR',
          'inr_amount': _amount,
        },
      );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final orderId = body['razorpay_order_id']?.toString();
      final keyId = body['key_id']?.toString();
      final reference = body['reference']?.toString();
      if (body['success'] == true &&
          orderId != null &&
          keyId != null &&
          reference != null &&
          reference.isNotEmpty) {
        _orderId = orderId;
        _keyId = keyId;
        _reference = reference;
      } else {
        error =
            body['error']?.toString() ??
            'Could not create payment order. Please try again.';
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      error =
          (data is Map ? data['error']?.toString() : null) ??
          'Could not create payment order. Please try again.';
    } catch (_) {
      error = 'Could not start payment. Please try again.';
    }

    if (!mounted) return false;
    setState(() {
      if (overlay) _processing = false;
      if (error != null) _errorMessage = error;
    });
    return error == null;
  }

  /// Methods enabled on the Razorpay account (banks, wallets, EMI plans).
  /// Needs the key, which arrives with the order. Reset on failure so
  /// reopening the section retries.
  Future<Map<String, dynamic>> _loadMethods() {
    return _methods ??=
        () async {
          if (!await _ensureWalletOrder(overlay: false)) {
            throw Exception(_errorMessage ?? 'order');
          }
          return _service.getPaymentMethods(keyId: _keyId!);
        }().catchError((Object e) {
          _methods = null;
          throw e;
        });
  }

  /// Fills [_contact]/[_email] from the profile, asking for whichever is
  /// missing. Returns false if the user dismisses the prompt.
  Future<bool> _ensureContactDetails() async {
    final user = sl<PreferencesManager>().getUserData() ?? {};
    if (_contact.isEmpty)
      _contact = (user['phone_number'] ?? '').toString().trim();
    if (_email.isEmpty) _email = (user['email'] ?? '').toString().trim();
    if (_contact.isNotEmpty && _email.isNotEmpty) return true;

    final details = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(20)),
        ),
      ),
      builder: (_) => _ContactDetailsSheet(
        askPhone: _contact.isEmpty,
        askEmail: _email.isEmpty,
      ),
    );
    if (details == null) return false;
    if (_contact.isEmpty) _contact = details.$1;
    if (_email.isEmpty) _email = details.$2;
    return true;
  }

  // ==================== PAYMENT ====================

  /// Charges the order with a method-specific payload (merged into the
  /// common fields), then verifies and credits the wallet.
  Future<void> _pay(Map<String, dynamic> method) async {
    if (_processing) return;
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!await _ensureContactDetails() || !mounted) return;
    if (!await _ensureWalletOrder() || !mounted) return;

    setState(() {
      _processing = true;
      _statusMessage = 'Complete the payment to continue...';
    });

    try {
      final result = await _service.submitPayment(
        keyId: _keyId!,
        data: {
          'amount': (_amount * 100).round(),
          'currency': 'INR',
          'order_id': _orderId,
          'email': _email,
          'contact': _contact,
          'description': 'Wallet Top-up',
          ...method,
        },
      );
      await _verifyAndCredit(result);
    } on RazorpayCustomCheckoutException catch (e) {
      final msg = e.message.toLowerCase();
      _fail(
        msg.contains('cancel')
            ? 'Payment cancelled. You can try again.'
            : e.message,
      );
    }
  }

  Future<void> _payWithUpiApp(UpiApp app) => _pay({
    'method': 'upi',
    '_[flow]': 'intent',
    'upi_app_package_name': app.package,
  });

  Future<void> _payWithGooglePay() async {
    if (_processing) return;
    final apps = await _upiApps;
    final gpay = apps.where((a) => a.isGooglePay).firstOrNull;
    if (!mounted) return;
    if (gpay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Google Pay isn't installed on this device. Pay with another UPI app or scan a QR.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _open = 'upi');
      return;
    }
    await _payWithUpiApp(gpay);
  }

  Future<void> _verifyAndCredit(RazorpayCustomPaymentResult result) async {
    final supportRef = result.paymentId.isNotEmpty
        ? result.paymentId
        : _reference;
    setState(() {
      _processing = true;
      _statusMessage = 'Verifying payment...';
      _errorMessage = null;
    });

    final dio = sl<DioClient>().instance;

    // Step 1: signature check. Nothing is credited until this passes.
    try {
      final verify = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': result.orderId,
          'razorpay_payment_id': result.paymentId,
          'razorpay_signature': result.signature,
          'reference_id': _reference,
        },
      );
      if (verify.data['success'] != true) {
        _fail(
          'Payment could not be verified. If money was deducted, contact '
          'support with reference: $supportRef',
        );
        return;
      }
    } catch (_) {
      _fail(
        'Payment could not be verified. If money was deducted, contact '
        'support with reference: $supportRef',
      );
      return;
    }

    // Step 2: settle the WalletTransaction created by /wallet/add-money/.
    await _creditWallet(supportRef: supportRef);
  }

  /// QR payments have no order/signature: the backend confirms the payment
  /// with Razorpay directly from [paymentId], then credits the wallet.
  Future<void> _creditFromQr(String paymentId) async {
    setState(() {
      _processing = true;
      _errorMessage = null;
    });
    await _creditWallet(paymentId: paymentId, supportRef: paymentId);
  }

  Future<void> _creditWallet({String? paymentId, String? supportRef}) async {
    if (!mounted) return;
    setState(() => _statusMessage = 'Adding money to your wallet...');
    try {
      final res = await sl<DioClient>().instance.post(
        Urls.walletVerifyPayment,
        data: {
          'reference': _reference,
          if (paymentId != null) 'razorpay_payment_id': paymentId,
        },
      );
      final body = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      if (body['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
    } catch (e) {
      print('Wallet credit after Razorpay top-up failed: $e');
    }
    _fail(
      'Payment received, but your wallet balance has not updated yet. '
      'Please contact support with reference: ${supportRef ?? _reference}',
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _errorMessage = message;
    });
  }

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        backgroundColor: CheckoutColors.page,
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        context.w(16),
                        context.h(16),
                        context.w(16),
                        context.h(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _amountCard(context),
                          SizedBox(height: context.h(16)),
                          if (_errorMessage != null) ...[
                            _errorBanner(context, _errorMessage!),
                            SizedBox(height: context.h(14)),
                          ],
                          _sectionLabel(context, 'Recommended'),
                          SizedBox(height: context.h(10)),
                          _googlePayTile(context),
                          SizedBox(height: context.h(8)),
                          _sectionLabel(context, 'All Payment Options'),
                          SizedBox(height: context.h(10)),
                          ..._sections(context),
                          _trustFooter(context),
                        ],
                      ),
                    ),
                  ),
                  _bottomBar(context),
                ],
              ),
              if (_processing) _processingOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context) {
    return [
      CheckoutAccordion(
        title: 'UPI',
        subtitle: 'Google Pay, PhonePe, Paytm & more · Scan QR',
        badge: 'INSTANT',
        leading: const CheckoutIcon('assets/NewIcons/upi.png'),
        expanded: _open == 'upi',
        onTap: () => _toggle('upi'),
        child: UpiSection(
          amount: _amount,
          busy: _busy,
          apps: _upiApps,
          onPayWithApp: _payWithUpiApp,
          onPayWithVpa: (vpa) =>
              _pay({'method': 'upi', '_[flow]': 'collect', 'vpa': vpa}),
          qrPanel: QrPayPanel(
            amount: _amount,
            prepareReference: () async =>
                await _ensureWalletOrder() ? _reference : null,
            onPaid: _creditFromQr,
          ),
        ),
      ),
      CheckoutAccordion(
        title: 'Credit / Debit Card',
        subtitle: 'Visa, Mastercard, RuPay, Amex & more',
        leading: const CheckoutIcon('assets/NewIcons/credit.png'),
        expanded: _open == 'card',
        onTap: () => _toggle('card'),
        child: CardForm(
          payLabel: 'Pay ${formatInr(_amount)}',
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
                amount: _amount,
                busy: _busy,
                methods: _loadMethods(),
                onPay: (bank) => _pay({'method': 'netbanking', 'bank': bank}),
              )
            : null,
      ),
      CheckoutAccordion(
        title: 'EMI',
        subtitle: 'Easy monthly instalments on credit cards',
        leading: _emiIcon(context),
        expanded: _open == 'emi',
        onTap: () => _toggle('emi'),
        child: _open == 'emi'
            ? EmiSection(
                amount: _amount,
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
      CheckoutAccordion(
        title: 'Wallets',
        subtitle: 'Paytm, PhonePe, Amazon Pay & more',
        leading: const CheckoutIcon('assets/NewIcons/wallet.png'),
        expanded: _open == 'wallet',
        onTap: () => _toggle('wallet'),
        child: _open == 'wallet'
            ? WalletsSection(
                amount: _amount,
                busy: _busy,
                methods: _loadMethods(),
                onPay: (wallet) => _pay({'method': 'wallet', 'wallet': wallet}),
              )
            : null,
      ),
      CheckoutAccordion(
        title: 'Pay Later',
        subtitle: 'LazyPay, Simpl, ICICI & more',
        leading: const CheckoutIcon('assets/NewIcons/pay_later.png'),
        expanded: _open == 'paylater',
        onTap: () => _toggle('paylater'),
        child: _open == 'paylater'
            ? PayLaterSection(
                amount: _amount,
                busy: _busy,
                methods: _loadMethods(),
                onPay: (provider) =>
                    _pay({'method': 'paylater', 'provider': provider}),
              )
            : const SizedBox.shrink(),
      ),
    ];
  }

  Widget _emiIcon(BuildContext context) => Container(
    width: context.w(34),
    height: context.w(34),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4E5),
      borderRadius: BorderRadius.circular(context.r(8)),
    ),
    child: Icon(
      Icons.calendar_month_rounded,
      size: context.w(20),
      color: const Color(0xFFF59E0B),
    ),
  );

  Widget _googlePayTile(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(14)),
        onTap: _busy ? null : _payWithGooglePay,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(14),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: CheckoutColors.stroke),
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
                      'Google Pay',
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                        color: CheckoutColors.ink,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      'Pay instantly from the Google Pay app',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: CheckoutColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(7),
                ),
                decoration: BoxDecoration(
                  color: CheckoutColors.primary,
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Text(
                  'PAY',
                  style: TextStyle(
                    fontSize: context.fs(12),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _processing ? null : () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: EdgeInsets.all(context.w(4)),
              child: Image.asset(
                'assets/NewIcons/arrowBack.png',
                width: context.w(15),
                height: context.w(15),
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Text(
              'Add Money',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(20),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.h(4),
            ),
            decoration: BoxDecoration(
              color: CheckoutColors.offer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(context.r(999)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: context.w(12),
                  color: CheckoutColors.offer,
                ),
                SizedBox(width: context.w(4)),
                Text(
                  'Secure',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    fontWeight: FontWeight.w700,
                    color: CheckoutColors.offer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFD9F3FF)],
        ),
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: CheckoutColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(40),
                height: context.w(40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CheckoutColors.primary,
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: context.w(22),
                  color: Colors.white,
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WanderNova Wallet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                        color: CheckoutColors.ink,
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      'Money is added instantly after payment',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(12),
                        color: CheckoutColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          const Divider(height: 1, color: CheckoutColors.stroke),
          SizedBox(height: context.h(12)),
          _fareLine(context, 'Recharge amount', formatInr(_amount)),
          SizedBox(height: context.h(8)),
          _fareLine(
            context,
            'Convenience fee',
            'FREE',
            valueColor: CheckoutColors.offer,
          ),
          SizedBox(height: context.h(12)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Due',
                  style: TextStyle(
                    fontSize: context.fs(18),
                    fontWeight: FontWeight.w800,
                    color: CheckoutColors.ink,
                  ),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatInr(_amount),
                      style: TextStyle(
                        fontSize: context.fs(20),
                        fontWeight: FontWeight.w800,
                        color: CheckoutColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fareLine(
    BuildContext context,
    String label,
    String value, {
    Color valueColor = CheckoutColors.ink,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.fs(13),
              color: CheckoutColors.muted,
            ),
          ),
        ),
        SizedBox(width: context.w(8)),
        Text(
          value,
          style: TextStyle(
            fontSize: context.fs(13),
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
      fontSize: context.fs(16),
      fontWeight: FontWeight.w700,
      color: CheckoutColors.ink,
    ),
  );

  Widget _trustFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: context.w(16),
            color: CheckoutColors.muted,
          ),
          SizedBox(width: context.w(6)),
          Flexible(
            child: Text(
              '100% Secure Payments · Powered by Razorpay',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(11.5),
                color: CheckoutColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatInr(_amount),
                    style: TextStyle(
                      fontSize: context.fs(20),
                      fontWeight: FontWeight.w800,
                      color: CheckoutColors.ink,
                    ),
                  ),
                ),
                Text(
                  'Amount to be added',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: CheckoutColors.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(12)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: context.w(14),
                color: CheckoutColors.offer,
              ),
              SizedBox(width: context.w(4)),
              Text(
                'Secured by Razorpay',
                style: TextStyle(
                  fontSize: context.fs(11.5),
                  fontWeight: FontWeight.w600,
                  color: CheckoutColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _processingOverlay(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.w(40)),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(24),
              vertical: context.h(24),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.r(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: CheckoutColors.primary),
                SizedBox(height: context.h(16)),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(13.5),
                    fontWeight: FontWeight.w600,
                    color: CheckoutColors.ink,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  'Please do not close the app or press back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(11.5),
                    color: CheckoutColors.muted,
                  ),
                ),
              ],
            ),
          ),
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
          Icon(
            Icons.error_outline_rounded,
            size: context.w(16),
            color: CheckoutColors.error,
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: CheckoutColors.error,
                fontSize: context.fs(12),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(
              Icons.close_rounded,
              size: context.w(16),
              color: CheckoutColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Collects the mobile number and/or email Razorpay needs when the user's
/// profile doesn't have them. Pops `(phone, email)`; fields not asked for are
/// returned empty.
class _ContactDetailsSheet extends StatefulWidget {
  final bool askPhone;
  final bool askEmail;

  const _ContactDetailsSheet({required this.askPhone, required this.askEmail});

  @override
  State<_ContactDetailsSheet> createState() => _ContactDetailsSheetState();
}

class _ContactDetailsSheetState extends State<_ContactDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(
    BuildContext context,
    String label,
    String hint, {
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(14),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (_phoneCtrl.text.trim(), _emailCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.w(20),
        right: context.w(20),
        top: context.h(20),
        bottom: MediaQuery.of(context).viewInsets.bottom + context.h(20),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Contact details',
                style: TextStyle(
                  fontSize: context.fs(18),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: context.h(4)),
              Text(
                'Required by the payment gateway to send payment updates.',
                style: TextStyle(
                  fontSize: context.fs(12.5),
                  color: AppColors.subhead,
                ),
              ),
              SizedBox(height: context.h(18)),
              if (widget.askPhone) ...[
                TextFormField(
                  controller: _phoneCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.askEmail
                      ? TextInputAction.next
                      : TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _decoration(
                    context,
                    'Mobile number',
                    '10-digit number',
                    prefix: '+91 ',
                  ),
                  validator: (v) =>
                      RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Enter a valid 10-digit mobile number',
                  onFieldSubmitted: (_) => widget.askEmail ? null : _submit(),
                ),
                SizedBox(height: context.h(14)),
              ],
              if (widget.askEmail) ...[
                TextFormField(
                  controller: _emailCtrl,
                  autofocus: !widget.askPhone,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: _decoration(context, 'Email', 'you@example.com'),
                  validator: (v) =>
                      RegExp(
                        r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$',
                      ).hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Enter a valid email address',
                  onFieldSubmitted: (_) => _submit(),
                ),
                SizedBox(height: context.h(14)),
              ],
              SizedBox(height: context.h(6)),
              SizedBox(
                height: context.h(48),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.AppBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: context.fs(15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
