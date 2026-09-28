import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';
import 'package:wander_nova/views/flight_payment/presentation/screen/ak_custom_checkout_args.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/card_form.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/checkout_ui.dart';
import 'package:wander_nova/views/wallet/wallet/screen/checkout/method_sections.dart';

/// Full-screen accordion checkout (MakeMyTrip-style) for flights, hotels and
/// transport. Accepts an existing Razorpay order via [AkCustomCheckoutArgs]
/// and pops a [RazorpayCustomPaymentResult] on success, or null on cancel.
///
/// Replaces the four separate method screens (AkCardPaymentScreen,
/// AkUpiPaymentScreen, AkNetbankingPaymentScreen, AkWalletProviderPaymentScreen).
class AkUnifiedCheckoutScreen extends StatefulWidget {
  final AkCustomCheckoutArgs args;

  const AkUnifiedCheckoutScreen({super.key, required this.args});

  @override
  State<AkUnifiedCheckoutScreen> createState() =>
      _AkUnifiedCheckoutScreenState();
}

class _AkUnifiedCheckoutScreenState extends State<AkUnifiedCheckoutScreen> {
  final _service = RazorpayCustomCheckoutService();

  bool _processing = false;
  String _statusMessage = 'Processing payment...';
  String? _errorMessage;
  String? _open = 'upi';

  late final Future<List<UpiApp>> _upiApps =
      _service.getUpiApps().catchError((_) => <UpiApp>[]);

  Future<Map<String, dynamic>>? _methods;

  AkCustomCheckoutArgs get _args => widget.args;

  // ==================== PAYMENT ====================

  Future<Map<String, dynamic>> _loadMethods() {
    return _methods ??=
        _service
            .getPaymentMethods(keyId: _args.keyId)
            .catchError((Object e) {
              _methods = null;
              throw e;
            });
  }

  Future<void> _pay(Map<String, dynamic> method) async {
    if (_processing) return;
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    setState(() {
      _processing = true;
      _statusMessage = 'Complete the payment to continue...';
    });

    try {
      final result = await _service.submitPayment(
        keyId: _args.keyId,
        data: {
          'amount': _args.amountInPaise,
          'currency': 'INR',
          'order_id': _args.orderId,
          'email': _args.email,
          'contact': _args.contact,
          'description': _args.description,
          ...method,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } on RazorpayCustomCheckoutException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('cancel')) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled. You can try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _processing = false;
          _errorMessage = e.message;
        });
      }
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
            "Google Pay isn't installed on this device. Pay with another UPI app.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _open = 'upi');
      return;
    }
    await _payWithUpiApp(gpay);
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
        subtitle: 'Google Pay, PhonePe, Paytm & more',
        badge: 'INSTANT',
        leading: const CheckoutIcon('assets/NewIcons/upi.png'),
        expanded: _open == 'upi',
        onTap: () => _toggle('upi'),
        child: _open == 'upi' ? _upiBody(context) : null,
      ),
      CheckoutAccordion(
        title: 'Credit / Debit Card',
        subtitle: 'Visa, Mastercard, RuPay, Amex & more',
        leading: const CheckoutIcon('assets/NewIcons/credit.png'),
        expanded: _open == 'card',
        onTap: () => _toggle('card'),
        child: CardForm(
          payLabel: 'Pay ${formatInr(_args.amountInInr)}',
          busy: _processing,
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
                amount: _args.amountInInr,
                busy: _processing,
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
                amount: _args.amountInInr,
                busy: _processing,
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
                amount: _args.amountInInr,
                busy: _processing,
                methods: _loadMethods(),
                onPay: (wallet) =>
                    _pay({'method': 'wallet', 'wallet': wallet}),
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
                amount: _args.amountInInr,
                busy: _processing,
                methods: _loadMethods(),
                onPay: (provider) =>
                    _pay({'method': 'paylater', 'provider': provider}),
              )
            : const SizedBox.shrink(),
      ),
    ];
  }

  // ---- Inline UPI body (apps + UPI ID tabs, no QR) ----

  Widget _upiBody(BuildContext context) {
    return _UpiBodyWidget(
      amount: _args.amountInInr,
      busy: _processing,
      apps: _upiApps,
      onPayWithApp: _payWithUpiApp,
      onPayWithVpa: (vpa) =>
          _pay({'method': 'upi', '_[flow]': 'collect', 'vpa': vpa}),
    );
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
      color: const Color(0xFFE67E22),
    ),
  );

  // ---- Header ----

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
              'Payment',
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

  // ---- Amount card ----

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
                  Icons.receipt_long_rounded,
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
                      _args.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w700,
                        color: CheckoutColors.ink,
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
                      formatInr(_args.amountInInr),
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

  // ---- Google Pay tile ----

  Widget _googlePayTile(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.r(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.r(14)),
        onTap: _processing ? null : _payWithGooglePay,
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

  // ---- Misc helpers ----

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
                    formatInr(_args.amountInInr),
                    style: TextStyle(
                      fontSize: context.fs(20),
                      fontWeight: FontWeight.w800,
                      color: CheckoutColors.ink,
                    ),
                  ),
                ),
                Text(
                  'Total amount',
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

// ---------------------------------------------------------------------------
// Inline UPI body — two tabs: UPI Apps (intent) + UPI ID (collect). No QR.
// ---------------------------------------------------------------------------

class _UpiBodyWidget extends StatefulWidget {
  final double amount;
  final bool busy;
  final Future<List<UpiApp>> apps;
  final ValueChanged<UpiApp> onPayWithApp;
  final ValueChanged<String> onPayWithVpa;

  const _UpiBodyWidget({
    required this.amount,
    required this.busy,
    required this.apps,
    required this.onPayWithApp,
    required this.onPayWithVpa,
  });

  @override
  State<_UpiBodyWidget> createState() => _UpiBodyWidgetState();
}

class _UpiBodyWidgetState extends State<_UpiBodyWidget> {
  int _tab = 0; // 0 = UPI Apps, 1 = UPI ID
  final _vpaKey = GlobalKey<FormState>();
  final _vpa = TextEditingController();

  static const _tabs = ['UPI Apps', 'UPI ID'];

  @override
  void dispose() {
    _vpa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckoutTabs(
          tabs: _tabs,
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        SizedBox(height: context.h(16)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(_tab),
            child: _tab == 0 ? _appsTab(context) : _upiIdTab(context),
          ),
        ),
      ],
    );
  }

  Widget _appsTab(BuildContext context) {
    return FutureBuilder<List<UpiApp>>(
      future: widget.apps,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CheckoutColors.primary,
              ),
            ),
          );
        }
        final apps = snap.data ?? [];
        if (apps.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(12)),
            child: Text(
              'No UPI apps detected on this device. Use UPI ID instead.',
              style: TextStyle(
                fontSize: context.fs(13),
                color: CheckoutColors.muted,
              ),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: context.h(12),
            crossAxisSpacing: context.w(8),
            childAspectRatio: 0.8,
          ),
          itemCount: apps.length,
          itemBuilder: (_, i) {
            final app = apps[i];
            return GestureDetector(
              onTap: widget.busy ? null : () => widget.onPayWithApp(app),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: context.w(48),
                    height: context.w(48),
                    decoration: BoxDecoration(
                      color: CheckoutColors.page,
                      borderRadius: BorderRadius.circular(context.r(12)),
                      border: Border.all(color: CheckoutColors.stroke),
                    ),
                    child: Center(
                      child: Text(
                        app.name.isNotEmpty
                            ? app.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: context.fs(20),
                          fontWeight: FontWeight.w700,
                          color: CheckoutColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.fs(11),
                      color: CheckoutColors.ink,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _upiIdTab(BuildContext context) {
    return Form(
      key: _vpaKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _vpa,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: checkoutInput(
              context,
              'UPI ID',
              hint: 'yourname@okhdfcbank',
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                size: context.w(18),
              ),
            ),
            validator: (v) =>
                RegExp(
                  r'^[\w.\-]{2,256}@[a-zA-Z][a-zA-Z0-9.]{1,64}$',
                ).hasMatch((v ?? '').trim())
                ? null
                : 'Enter a valid UPI ID',
          ),
          SizedBox(height: context.h(10)),
          const InlineNote(
            'A payment request will be sent to your UPI app. Approve it within 5 minutes.',
          ),
          SizedBox(height: context.h(14)),
          CheckoutPayButton(
            label: 'Verify & Pay ${formatInr(widget.amount)}',
            loading: widget.busy,
            onPressed: () {
              FocusScope.of(context).unfocus();
              if (_vpaKey.currentState!.validate())
                widget.onPayWithVpa(_vpa.text.trim());
            },
          ),
        ],
      ),
    );
  }
}
