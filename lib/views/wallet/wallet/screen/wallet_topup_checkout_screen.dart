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
import 'package:wander_nova/common_widgets/app_loader.dart';

/// Full-screen wallet top-up checkout (MakeMyTrip-style accordion): UPI
/// (apps / UPI ID / QR), cards, net banking, EMI and wallets, all paid
/// in-page through Razorpay Custom Checkout (native SDK on Android and iOS).
///
/// Flow (same as the web app):
///   /wallet/add-money/ (creates the WalletTransaction + Razorpay order)
///   → Razorpay charges the order (UPI intent / card / bank / wallet)
///   → /payments/razorpay/verify/ → /wallet/verify-payment/ (credit)
/// QR payments have no Razorpay order: /wallet/add-money/ (gateway
///   razorpay_qr) → razorpay/create-qr-code/ → poll qr-status →
///   /wallet/verify-payment/ with the razorpay_payment_id (QrPayController).
///
/// Pops `true` only once the wallet backend confirms the credit.
class WalletTopUpCheckoutScreen extends StatefulWidget {
  /// Amount to start on, in INR. The traveller edits it here — the design
  /// puts the amount and the methods on one screen — so this is only a
  /// starting point, not the amount that gets charged.
  final double? initialAmount;

  const WalletTopUpCheckoutScreen({super.key, this.initialAmount});

  @override
  State<WalletTopUpCheckoutScreen> createState() =>
      _WalletTopUpCheckoutScreenState();
}

class _WalletTopUpCheckoutScreenState extends State<WalletTopUpCheckoutScreen> {
  final _service = RazorpayCustomCheckoutService();

  bool _processing = false;
  String _statusMessage = '';
  String? _errorMessage;
  /// Which method row is selected. The design shows exactly one open at a
  /// time, with its body inline under the row.
  String? _open = 'card';
  int? _selectedQuickAmount;

  /// Lets the screen's PAY NOW submit the open method. Each section binds its
  /// own submit here while it is on screen.
  final _submit = CheckoutSubmitController();

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

  /// The amount being topped up, in rupees. Mutable because it is entered on
  /// this screen.
  double _amount = 0;
  late final TextEditingController _amountCtrl;

  /// The quick-add chips under the amount field, as the design lists them.
  static const _quickAmounts = <int>[20, 50, 100, 250, 500];

  // Lives as long as this screen, so a QR keeps being polled while its tab
  // is hidden or the UPI section is collapsed. Rebuilt whenever the amount
  // changes, because a QR poster is minted for one amount.
  late QrPayController _qr;

  bool get _busy => _processing;

  /// The amount is only payable once it is a real, positive figure — the
  /// gateway rejects a zero order, and an empty field should not look
  /// chargeable.
  bool get _amountIsPayable => _amount > 0;

  @override
  void initState() {
    super.initState();
    _amount = double.parse(((widget.initialAmount ?? 0)).toStringAsFixed(2));
    _amountCtrl = TextEditingController(
      text: _amount > 0 ? _amount.toStringAsFixed(0) : '',
    );
    _qr = QrPayController(amount: _amount, onPaid: _creditFromQr);
  }

  @override
  void dispose() {
    _submit.dispose();
    _amountCtrl.dispose();
    _qr.dispose();
    super.dispose();
  }

  /// Applies a new amount and throws away everything minted for the old one.
  ///
  /// The order, its key and its reference are all created for a specific
  /// figure, so reusing them after an edit would authorise one amount against
  /// an order for another — which the gateway refuses. The QR poster is
  /// per-amount too, so it is rebuilt rather than left showing a stale total.
  void _applyAmount(double value) {
    final next = double.parse(value.toStringAsFixed(2));
    if (next == _amount) return;

    final oldQr = _qr;
    setState(() {
      _amount = next;
      _orderId = null;
      _keyId = null;
      _reference = null;
      _methods = null;
      _errorMessage = null;
      _qr = QrPayController(amount: next, onPaid: _creditFromQr);
    });
    oldQr.dispose();
  }

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
    // The amount is entered on this screen, so a method can be reached before
    // one has been typed. The gateway rejects a zero order; say so here
    // rather than letting it fail downstream.
    if (!_amountIsPayable) {
      setState(
        () => _errorMessage = 'Enter the amount you want to add first.',
      );
      return;
    }
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
    await _creditWallet(reference: _reference!, supportRef: supportRef);
  }

  /// QR payments have no order/signature: the backend confirms the payment
  /// with Razorpay directly from [paymentId], then credits the QR's own
  /// wallet transaction [reference].
  Future<bool> _creditFromQr(String reference, String paymentId) async {
    if (!mounted) return false;
    setState(() {
      _processing = true;
      _errorMessage = null;
    });
    return _creditWallet(
      reference: reference,
      paymentId: paymentId,
      supportRef: paymentId,
    );
  }

  /// Returns whether the wallet was credited (the screen then closes).
  Future<bool> _creditWallet({
    required String reference,
    String? paymentId,
    String? supportRef,
  }) async {
    if (!mounted) return false;
    setState(() => _statusMessage = 'Adding money to your wallet...');
    try {
      final res = await sl<DioClient>().instance.post(
        Urls.walletVerifyPayment,
        data: {
          'reference': reference,
          if (paymentId != null) 'razorpay_payment_id': paymentId,
        },
      );
      final body = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      if (body['success'] == true) {
        if (mounted) Navigator.pop(context, true);
        return true;
      }
    } catch (e) {
      print('Wallet credit after Razorpay top-up failed: $e');
    }
    _fail(
      'Payment received, but your wallet balance has not updated yet. '
      'Please contact support with reference: ${supportRef ?? reference}',
    );
    return false;
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _errorMessage = message;
    });
  }

  /// Selects a method. Radio rows, so tapping the open one keeps it open —
  /// there is always a method selected for PAY NOW to act on.
  void _select(String id) {
    if (_open == id) return;
    // The outgoing section's submit must not linger on the controller.
    _submit.unbind();
    setState(() => _open = id);
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        backgroundColor: AppColors.white,
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
                          SizedBox(height: context.h(20)),
                          if (_errorMessage != null) ...[
                            _errorBanner(context, _errorMessage!),
                            SizedBox(height: context.h(14)),
                          ],
                          // Not in the Figma frame, but kept: this tile is the
                          // only way into the UPI *intent* flow (paying by
                          // opening a UPI app), which the UPI row's body does
                          // not offer. Removing it would drop a payment path.
                          _googlePayTile(context),
                          SizedBox(height: context.h(14)),
                          ..._sections(context),
                          _trustFooter(context),
                        ],
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _submit,
                    builder: (context, _) => _bottomBar(context),
                  ),
                ],
              ),
              if (_processing) _processingOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  /// The method rows, in the design's order: cards first (the row it shows
  /// open), then UPI, Net Banking, EMI and Wallet & Pay Later.
  ///
  /// EMI is not drawn in the Figma frame but is kept — it is a payment option
  /// this screen already offered, and dropping it would take functionality
  /// away. It uses the same row as the rest.
  List<Widget> _sections(BuildContext context) {
    return [
      _MethodRow(
        id: 'card',
        title: 'Credit & Debit Cards',
        selected: _open == 'card',
        onTap: () => _select('card'),
        leading: const CheckoutIcon('assets/NewIcons/credit.png'),
        brands: const [
          _Brand('VISA', Color(0xFF1A1F71), Color(0xFFEAF0FB)),
          _Brand('MC', Color(0xFFEB001B), Color(0xFF111111)),
          _Brand('AMEX', Colors.white, Color(0xFF2E77BC)),
          _Brand('RuPay', Colors.white, Color(0xFF0B2B5B)),
        ],
        child: CardForm(
          payLabel: 'Pay ${formatInr(_amount)}',
          busy: _busy,
          submitController: _submit,
          outlinedLabels: true,
          onSubmit: (card) => _pay({'method': 'card', 'card': card}),
        ),
      ),
      _MethodRow(
        id: 'upi',
        title: 'UPI',
        subtitle: 'Pay Directly From Your Bank Account',
        selected: _open == 'upi',
        onTap: () => _select('upi'),
        leading: const CheckoutIcon('assets/NewIcons/upi.png'),
        brands: const [
          _Brand('GPay', Color(0xFF1A73E8), Color(0xFFEAF1FE)),
          _Brand('PhonePe', Colors.white, Color(0xFF5F259F)),
          _Brand('Paytm', Colors.white, Color(0xFF002970)),
        ],
        child: UpiSection(
          amount: _amount,
          busy: _busy,
          apps: _upiApps,
          onPayWithApp: _payWithUpiApp,
          submitController: _submit,
          onPayWithVpa: (vpa) =>
              _pay({'method': 'upi', '_[flow]': 'collect', 'vpa': vpa}),
          qrPanel: _amountIsPayable ? QrPayPanel(controller: _qr) : null,
        ),
      ),
      _MethodRow(
        id: 'netbanking',
        title: 'Net Banking',
        subtitle: '40+ Banks available',
        selected: _open == 'netbanking',
        onTap: () => _select('netbanking'),
        leading: const CheckoutIcon('assets/NewIcons/net_banking.png'),
        brands: const [
          _Brand('HDFC', Colors.white, Color(0xFFE02020)),
          _Brand('ICICI', Colors.white, Color(0xFFF37920)),
          _Brand('SBI', Colors.white, Color(0xFF22409A)),
          _Brand('AXIS', Colors.white, Color(0xFF97144D)),
        ],
        child: _open == 'netbanking'
            ? NetbankingSection(
                amount: _amount,
                busy: _busy,
                methods: _loadMethods(),
                submitController: _submit,
                onPay: (bank) => _pay({'method': 'netbanking', 'bank': bank}),
              )
            : null,
      ),
      // _MethodRow(
      //   id: 'emi',
      //   title: 'EMI',
      //   subtitle: 'Easy monthly instalments on credit cards',
      //   selected: _open == 'emi',
      //   onTap: () => _select('emi'),
      //   leading: _emiIcon(context),
      //   child: _open == 'emi'
      //       ? EmiSection(
      //           amount: _amount,
      //           busy: _busy,
      //           methods: _loadMethods(),
      //           onPay: (months, card) => _pay({
      //             'method': 'emi',
      //             'emi_duration': months,
      //             'card': card,
      //           }),
      //         )
      //       : null,
      // ),
      _MethodRow(
        id: 'wallet',
        title: 'Wallet & Pay Later',
        subtitle: 'Airtel Money, Mobikwik, Ola Money',
        selected: _open == 'wallet',
        onTap: () => _select('wallet'),
        leading: const CheckoutIcon('assets/NewIcons/wallet.png'),
        brands: const [
          _Brand('Airtel', Colors.white, Color(0xFFE40000)),
          _Brand('Mobik', Colors.white, Color(0xFF2E6CB5)),
        ],
        child: _open == 'wallet'
            ? WalletsPayLaterSection(
                amount: _amount,
                busy: _busy,
                methods: _loadMethods(),
                submitController: _submit,
                onPayWallet: (wallet) =>
                    _pay({'method': 'wallet', 'wallet': wallet}),
                onPayLater: (provider) =>
                    _pay({'method': 'paylater', 'provider': provider}),
              )
            : null,
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
                        fontSize: context.fs(13),
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
                        fontSize: context.fs(11),
                        color: CheckoutColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(8)),
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
        horizontal: context.w(14),
        vertical: context.h(10),
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
              'Add Top Up',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.fs(19),
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The amount entry at the top of the design: a centred `₹ 250` field, the
  /// fee note, then the quick-add chips.
  Widget _amountCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'ENTER TOP UP AMOUNT',
            style: TextStyle(
              fontSize: context.fs(11),
              fontWeight: FontWeight.w400,
              color: CheckoutColors.muted,
            ),
          ),
        ),
        SizedBox(height: context.h(14)),
        _amountField(context),
        SizedBox(height: context.h(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: context.w(15),
              color: CheckoutColors.offer,
            ),
            SizedBox(width: context.w(6)),
            Flexible(
              child: Text(
                'No convenience fee · Added instantly',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fs(11),
                  fontWeight: FontWeight.w400,
                  color: CheckoutColors.muted,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(16)),
        _quickAmountRow(context),
      ],
    );
  }

  Widget _amountField(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.w(240)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '₹',
              style: TextStyle(
                fontSize: context.fs(22),
                fontWeight: FontWeight.w700,
                color: CheckoutColors.ink,
              ),
            ),
            SizedBox(width: context.w(10)),
            Flexible(
              child: TextField(
                controller: _amountCtrl,
                enabled: !_busy,
                autofocus: _amount <= 0,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (value) =>
                    _applyAmount(double.tryParse(value.trim()) ?? 0),
                style: TextStyle(
                  fontSize: context.fs(24),
                  fontWeight: FontWeight.w700,
                  color: CheckoutColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontSize: context.fs(24),
                    fontWeight: FontWeight.w700,
                    color: CheckoutColors.muted.withValues(alpha: 0.5),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: context.h(6),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: CheckoutColors.stroke),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: CheckoutColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in _quickAmounts) ...[
            _QuickAmountChip(
              label: '+₹$value',
              selected: _selectedQuickAmount == value,
              onTap: _busy
                  ? null
                  : () {
                final next = _amount + value;
                _amountCtrl.text = next
                    .toStringAsFixed(next % 1 == 0 ? 0 : 2);
                setState(() => _selectedQuickAmount = value);
                _applyAmount(next);
              },
            ),
            if (value != _quickAmounts.last) SizedBox(width: context.w(19)),
          ],
        ],
      ),
    );
  }

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

  /// The design's orange call to action.
  ///
  /// Each method still submits through its own section — a card needs its
  /// form, net banking needs a bank — so this bar carries the total and
  /// points at the chosen method rather than pretending to charge on its own.
  Widget _bottomBar(BuildContext context) {
    final ready = _amountIsPayable;
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(12),
        context.w(16),
        context.h(0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.06),
        //     blurRadius: 10,
        //     offset: const Offset(0, -2),
        //   ),
        // ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (!ready || _busy || !_submit.canSubmit)
                  ? null
                  : _submit.submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.OrangeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE6E8EC),
                disabledForegroundColor: CheckoutColors.muted,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: context.h(16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'PAY NOW',
                    style: TextStyle(
                      fontSize: context.fs(12.5),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  Icon(Icons.arrow_forward_rounded, size: context.w(16)),
                ],
              ),
            ),
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
            child: AppLoadingView(message: _statusMessage, hint: 'Please do not close the app or press back'),
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

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const _QuickAmountChip({
    required this.label,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.AppBlue : Colors.white,
      borderRadius: BorderRadius.circular(context.r(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(8),
            vertical: context.h(7),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(8)),
            border: Border.all(color: CheckoutColors.stroke, width: 0.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w400,
              color: selected ? Colors.white : CheckoutColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small brand mark drawn as a chip, so the row shows the schemes the
/// design lists without needing a logo asset per network.
class _Brand {
  final String label;
  final Color fg;
  final Color bg;

  const _Brand(this.label, this.fg, this.bg);
}

class _BrandCluster extends StatelessWidget {
  final List<_Brand> brands;

  const _BrandCluster(this.brands);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final b in brands)
          Container(
            margin: EdgeInsets.only(left: context.w(4)),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(5),
              vertical: context.h(3),
            ),
            decoration: BoxDecoration(
              color: b.bg,
              borderRadius: BorderRadius.circular(context.r(4)),
            ),
            child: Text(
              b.label,
              style: TextStyle(
                fontSize: context.fs(8),
                fontWeight: FontWeight.w800,
                color: b.fg,
              ),
            ),
          ),
      ],
    );
  }
}

/// One payment method, as the design draws it: a radio, the method's icon,
/// its name and subtitle, the scheme chips, and — when selected — its own
/// section inline underneath.
///
/// Replaces the chevron accordion on this screen only. The body is whatever
/// section widget the screen passes in, unchanged, so each method still pays
/// exactly as it did.
class _MethodRow extends StatelessWidget {
  final String id;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final List<_Brand> brands;
  final Widget? child;

  const _MethodRow({
    required this.id,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.leading,
    this.subtitle,
    this.brands = const [],
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final body = child;
    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        // Only the open row is boxed, as in the design — the collapsed ones
        // are plain rows separated by their own spacing.
        border: selected
            ? Border.all(color: CheckoutColors.stroke, width: 0.5)
            : Border.all(color: Colors.transparent, width: 0.5),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(context.r(10)),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: context.w(20),
                  color: selected
                      ? CheckoutColors.primary
                      : const Color(0xFFC6CDD6),
                ),
                SizedBox(width: context.w(10)),
                leading,
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.fs(13),
                          fontWeight: FontWeight.w700,
                          color: CheckoutColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: context.h(2)),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.fs(10),
                            color: CheckoutColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (brands.isNotEmpty) ...[
                  SizedBox(width: context.w(6)),
                  // Capped so the method name and subtitle keep their room;
                  // the chips scale down instead of truncating the text.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: context.w(118)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _BrandCluster(brands),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (selected && body != null) ...[
            SizedBox(height: context.h(14)),
            Container(
              padding: EdgeInsets.all(context.w(12)),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFD),
                borderRadius: BorderRadius.circular(context.r(12)),
                border: Border.all(color: CheckoutColors.stroke),
              ),
              child: body,
            ),
          ],
        ],
      ),
    );
  }
}

