import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';
import 'package:wander_nova/views/flight_payment/presentation/screen/ak_custom_checkout_args.dart';

/// Wallets (Paytm/PhonePe/Amazon Pay/etc.) for Razorpay Custom Checkout (doc
/// step 1.6, `method: "wallet"`). Not to be confused with the WanderNova
/// in-app wallet balance, which is a separate, non-Razorpay payment option
/// on [AkFlightPaymentScreen].
class AkWalletProviderPaymentScreen extends StatefulWidget {
  final AkCustomCheckoutArgs args;

  const AkWalletProviderPaymentScreen({super.key, required this.args});

  @override
  State<AkWalletProviderPaymentScreen> createState() => _AkWalletProviderPaymentScreenState();
}

class _AkWalletProviderPaymentScreenState extends State<AkWalletProviderPaymentScreen> {
  static const _pri = AppColors.AppBlue;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);

  static const _displayNames = {
    'payzapp': 'PayZapp',
    'olamoney': 'Ola Money',
    'phonepe': 'PhonePe',
    'airtelmoney': 'Airtel Money',
    'mobikwik': 'MobiKwik',
    'jiomoney': 'JioMoney',
    'amazonpay': 'Amazon Pay',
    'paypal': 'PayPal',
    'phonepeswitch': 'PhonePe',
  };

  final _service = RazorpayCustomCheckoutService();

  bool _loadingWallets = true;
  bool _paying = false;
  String? _errorMessage;
  String? _payingWalletCode;
  List<String> _wallets = [];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final methods = await _service.getPaymentMethods(keyId: widget.args.keyId);
      final wallet = methods['wallet'];
      final wallets = <String>[];
      if (wallet is Map) {
        wallet.forEach((code, enabled) {
          if (code is String && enabled == true) wallets.add(code);
        });
      }
      wallets.sort((a, b) => (_displayNames[a] ?? a).compareTo(_displayNames[b] ?? b));
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        _loadingWallets = false;
      });
    } on RazorpayCustomCheckoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingWallets = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _payWithWallet(String code) async {
    setState(() {
      _paying = true;
      _payingWalletCode = code;
      _errorMessage = null;
    });
    try {
      final result = await _service.submitPayment(
        keyId: widget.args.keyId,
        data: {
          'amount': widget.args.amountInPaise,
          'currency': 'INR',
          'order_id': widget.args.orderId,
          'email': widget.args.email,
          'contact': widget.args.contact,
          'method': 'wallet',
          'wallet': code,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on RazorpayCustomCheckoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _payingWalletCode = null;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          'Gift Cards & e-Wallets',
          style: TextStyle(color: Colors.black, fontSize: context.fs(18), fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.w(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay ₹${widget.args.amountInInr.toStringAsFixed(2)}',
                style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.w800, color: _ink),
              ),
              SizedBox(height: context.h(16)),
              if (_errorMessage != null) ...[
                _errorBanner(context, _errorMessage!),
                SizedBox(height: context.h(16)),
              ],
              Expanded(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loadingWallets) {
      return const Center(child: CircularProgressIndicator(color: _pri));
    }
    if (_wallets.isEmpty) {
      return Center(
        child: Text(
          'No wallets available on this account right now.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: context.fs(13)),
        ),
      );
    }
    return ListView.separated(
      itemCount: _wallets.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: _stroke),
      itemBuilder: (_, i) {
        final code = _wallets[i];
        final isPayingThis = _paying && _payingWalletCode == code;
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: context.h(4)),
          leading: Container(
            width: context.w(36),
            height: context.w(36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(context.r(8)),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, size: context.w(18), color: const Color(0xFFB45309)),
          ),
          title: Text(
            _displayNames[code] ?? code,
            style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: _ink),
          ),
          trailing: isPayingThis
              ? SizedBox(
                  width: context.w(20),
                  height: context.w(20),
                  child: const CircularProgressIndicator(strokeWidth: 2.2, color: _pri),
                )
              : Icon(Icons.chevron_right_rounded, color: _pri),
          onTap: _paying ? null : () => _payWithWallet(code),
        );
      },
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
            child: Text(
              message,
              style: TextStyle(color: const Color(0xffB42318), fontSize: context.fs(12)),
            ),
          ),
        ],
      ),
    );
  }
}
