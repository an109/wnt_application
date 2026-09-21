import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';
import 'package:wander_nova/views/flight_payment/presentation/screen/ak_custom_checkout_args.dart';

/// Netbanking for Razorpay Custom Checkout (doc step 1.6, `method:
/// "netbanking"`). The bank list comes from the account's real enabled
/// methods (doc step 1.4) — per the doc's own warning, a custom checkout
/// must never show banks that aren't actually activated for the account.
class AkNetbankingPaymentScreen extends StatefulWidget {
  final AkCustomCheckoutArgs args;

  const AkNetbankingPaymentScreen({super.key, required this.args});

  @override
  State<AkNetbankingPaymentScreen> createState() => _AkNetbankingPaymentScreenState();
}

class _AkNetbankingPaymentScreenState extends State<AkNetbankingPaymentScreen> {
  static const _pri = AppColors.AppBlue;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);

  final _service = RazorpayCustomCheckoutService();
  final _searchCtrl = TextEditingController();

  bool _loadingBanks = true;
  bool _paying = false;
  String? _errorMessage;
  String? _payingBankCode;
  List<MapEntry<String, String>> _banks = [];

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    try {
      final methods = await _service.getPaymentMethods(keyId: widget.args.keyId);
      final netbanking = methods['netbanking'];
      final banks = <MapEntry<String, String>>[];
      if (netbanking is Map) {
        netbanking.forEach((code, name) {
          if (code is String && name is String && name.isNotEmpty) {
            banks.add(MapEntry(code, name));
          }
        });
      }
      banks.sort((a, b) => a.value.compareTo(b.value));
      if (!mounted) return;
      setState(() {
        _banks = banks;
        _loadingBanks = false;
      });
    } on RazorpayCustomCheckoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBanks = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _payWithBank(String code) async {
    setState(() {
      _paying = true;
      _payingBankCode = code;
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
          'method': 'netbanking',
          'bank': code,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on RazorpayCustomCheckoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _payingBankCode = null;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _banks
        : _banks.where((b) => b.value.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          'Net Banking',
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
              if (!_loadingBanks && _banks.isNotEmpty)
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search your bank',
                    prefixIcon: Icon(Icons.search_rounded, color: _muted, size: context.w(20)),
                    contentPadding: EdgeInsets.symmetric(vertical: context.h(12)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.r(10)),
                      borderSide: const BorderSide(color: _stroke),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.r(10)),
                      borderSide: const BorderSide(color: _stroke),
                    ),
                  ),
                ),
              SizedBox(height: context.h(12)),
              Expanded(child: _body(context, filtered)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<MapEntry<String, String>> banks) {
    if (_loadingBanks) {
      return const Center(child: CircularProgressIndicator(color: _pri));
    }
    if (banks.isEmpty) {
      return Center(
        child: Text(
          'No banks available for netbanking right now.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: context.fs(13)),
        ),
      );
    }
    return ListView.separated(
      itemCount: banks.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: _stroke),
      itemBuilder: (_, i) {
        final bank = banks[i];
        final isPayingThis = _paying && _payingBankCode == bank.key;
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: context.h(4)),
          leading: Container(
            width: context.w(36),
            height: context.w(36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(context.r(8)),
            ),
            child: Icon(Icons.account_balance_rounded, size: context.w(18), color: _pri),
          ),
          title: Text(
            bank.value,
            style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w600, color: _ink),
          ),
          trailing: isPayingThis
              ? SizedBox(
                  width: context.w(20),
                  height: context.w(20),
                  child: const CircularProgressIndicator(strokeWidth: 2.2, color: _pri),
                )
              : Icon(Icons.chevron_right_rounded, color: _pri),
          onTap: _paying ? null : () => _payWithBank(bank.key),
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
