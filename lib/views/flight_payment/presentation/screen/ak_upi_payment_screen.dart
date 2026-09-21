import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';
import 'package:wander_nova/views/flight_payment/presentation/screen/ak_custom_checkout_args.dart';

/// UPI payment for Razorpay Custom Checkout (doc step 1.6, `method: "upi"`).
/// Two tabs: a working "Enter UPI ID" (VPA) flow, and a "Scan QR" tab that is
/// a styled placeholder only — the real QR generation/scanning is added
/// later, per instruction.
class AkUpiPaymentScreen extends StatefulWidget {
  final AkCustomCheckoutArgs args;

  const AkUpiPaymentScreen({super.key, required this.args});

  @override
  State<AkUpiPaymentScreen> createState() => _AkUpiPaymentScreenState();
}

class _AkUpiPaymentScreenState extends State<AkUpiPaymentScreen> with SingleTickerProviderStateMixin {
  static const _pri = AppColors.AppBlue;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);

  late final TabController _tabController;
  final _vpaCtrl = TextEditingController();
  final _service = RazorpayCustomCheckoutService();

  bool _processing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vpaCtrl.dispose();
    super.dispose();
  }

  bool get _isValidVpa => RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$').hasMatch(_vpaCtrl.text.trim());

  Future<void> _payWithVpa() async {
    if (!_isValidVpa) {
      setState(() => _errorMessage = 'Enter a valid UPI ID, e.g. name@bank');
      return;
    }
    setState(() {
      _processing = true;
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
          'method': 'upi',
          'vpa': _vpaCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on RazorpayCustomCheckoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
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
          'UPI Payment',
          style: TextStyle(color: Colors.black, fontSize: context.fs(18), fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _pri,
          unselectedLabelColor: _muted,
          indicatorColor: _pri,
          labelStyle: TextStyle(fontSize: context.fs(13.5), fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Enter UPI ID'),
            Tab(text: 'Scan QR'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _vpaTab(context),
            _qrPlaceholderTab(context),
          ],
        ),
      ),
    );
  }

  Widget _vpaTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.w(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pay ${_amountLabel()}',
            style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.w800, color: _ink),
          ),
          SizedBox(height: context.h(4)),
          Text(widget.args.description, style: TextStyle(fontSize: context.fs(12.5), color: _muted)),
          SizedBox(height: context.h(24)),
          if (_errorMessage != null) ...[
            _errorBanner(context, _errorMessage!),
            SizedBox(height: context.h(16)),
          ],
          Text(
            'UPI ID',
            style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: _ink),
          ),
          SizedBox(height: context.h(6)),
          TextField(
            controller: _vpaCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: context.fs(14), color: _ink),
            decoration: InputDecoration(
              hintText: 'yourname@bank',
              hintStyle: TextStyle(fontSize: context.fs(14), color: _muted),
              contentPadding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(14)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
                borderSide: const BorderSide(color: _stroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
                borderSide: const BorderSide(color: _stroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.r(10)),
                borderSide: const BorderSide(color: _pri),
              ),
            ),
          ),
          SizedBox(height: context.h(32)),
          SizedBox(
            width: double.infinity,
            height: context.h(50),
            child: ElevatedButton(
              onPressed: _processing ? null : _payWithVpa,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pri,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.r(12))),
              ),
              child: _processing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text(
                      'Pay ${_amountLabel()}',
                      style: TextStyle(color: Colors.white, fontSize: context.fs(15), fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder only — QR generation/scanning wiring comes later.
  Widget _qrPlaceholderTab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.w(16)),
      child: Column(
        children: [
          Text(
            'Pay ${_amountLabel()}',
            style: TextStyle(fontSize: context.fs(22), fontWeight: FontWeight.w800, color: _ink),
          ),
          SizedBox(height: context.h(24)),
          Container(
            width: context.w(220),
            height: context.w(220),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(color: _stroke, width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2_rounded, size: context.w(72), color: _muted),
                SizedBox(height: context.h(10)),
                Text(
                  'QR coming soon',
                  style: TextStyle(fontSize: context.fs(12.5), color: _muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(16)),
          Text(
            'Scan with any UPI app to pay ${_amountLabel()}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: context.fs(12.5), color: _muted),
          ),
        ],
      ),
    );
  }

  String _amountLabel() => '₹${widget.args.amountInInr.toStringAsFixed(2)}';

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
