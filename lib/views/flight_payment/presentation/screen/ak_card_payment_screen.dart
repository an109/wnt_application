import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';
import 'package:wander_nova/views/flight_payment/data/razorpay_custom_checkout_service.dart';
import 'package:wander_nova/views/flight_payment/presentation/screen/ak_custom_checkout_args.dart';

/// Card entry for Razorpay Custom Checkout (doc step 1.6, `method: "card"`).
/// Raw card details never leave this screen except inside the payload
/// handed to the native Razorpay SDK over the platform channel — the SDK
/// itself owns tokenisation/submission, this screen only collects input.
class AkCardPaymentScreen extends StatefulWidget {
  final AkCustomCheckoutArgs args;

  const AkCardPaymentScreen({super.key, required this.args});

  @override
  State<AkCardPaymentScreen> createState() => _AkCardPaymentScreenState();
}

class _AkCardPaymentScreenState extends State<AkCardPaymentScreen> {
  static const _pri = AppColors.AppBlue;
  static const _muted = AppColors.subhead;
  static const _stroke = Color(0xFFE6E8EC);
  static const _ink = Color(0xFF0F172A);

  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  final _service = RazorpayCustomCheckoutService();
  bool _processing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    final expiryParts = _expiryCtrl.text.split('/');
    final expiryMonth = int.tryParse(expiryParts[0]) ?? 0;
    final expiryYear = int.tryParse(expiryParts.length > 1 ? expiryParts[1] : '') ?? 0;

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
          'method': 'card',
          'card': {
            'number': _numberCtrl.text.replaceAll(' ', ''),
            'name': _nameCtrl.text.trim(),
            'expiry_month': expiryMonth,
            'expiry_year': expiryYear,
            'cvv': _cvvCtrl.text.trim(),
          },
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
          'Card Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: context.fs(18),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.w(16)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay ${_amountLabel()}',
                  style: TextStyle(
                    fontSize: context.fs(22),
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  widget.args.description,
                  style: TextStyle(fontSize: context.fs(12.5), color: _muted),
                ),
                SizedBox(height: context.h(24)),
                if (_errorMessage != null) ...[
                  _errorBanner(context, _errorMessage!),
                  SizedBox(height: context.h(16)),
                ],
                _label(context, 'Card Number'),
                _field(
                  context,
                  controller: _numberCtrl,
                  hint: '1234 5678 9012 3456',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  validator: (v) => (v == null || v.replaceAll(' ', '').length < 12)
                      ? 'Enter a valid card number'
                      : null,
                ),
                SizedBox(height: context.h(16)),
                _label(context, 'Name on Card'),
                _field(
                  context,
                  controller: _nameCtrl,
                  hint: 'As printed on the card',
                  keyboardType: TextInputType.name,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the cardholder name' : null,
                ),
                SizedBox(height: context.h(16)),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(context, 'Expiry (MM/YY)'),
                          _field(
                            context,
                            controller: _expiryCtrl,
                            hint: 'MM/YY',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryFormatter(),
                            ],
                            validator: (v) => (v == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(v))
                                ? 'Invalid'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.w(16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(context, 'CVV'),
                          _field(
                            context,
                            controller: _cvvCtrl,
                            hint: '123',
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (v) => (v == null || v.length < 3) ? 'Invalid' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(32)),
                SizedBox(
                  width: double.infinity,
                  height: context.h(50),
                  child: ElevatedButton(
                    onPressed: _processing ? null : _pay,
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
                            style: TextStyle(
                              color: Colors.white,
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
      ),
    );
  }

  String _amountLabel() => '₹${widget.args.amountInInr.toStringAsFixed(2)}';

  Widget _label(BuildContext context, String text) => Padding(
        padding: EdgeInsets.only(bottom: context.h(6)),
        child: Text(
          text,
          style: TextStyle(fontSize: context.fs(12.5), fontWeight: FontWeight.w600, color: _ink),
        ),
      );

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(fontSize: context.fs(14), color: _ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: context.fs(14), color: _muted),
        contentPadding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(14)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.r(10)),
          borderSide: BorderSide(color: _stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.r(10)),
          borderSide: BorderSide(color: _stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.r(10)),
          borderSide: const BorderSide(color: _pri),
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

/// Auto-inserts the `/` in `MM/YY` as the user types digits.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 && digits.length > 2) buffer.write('/');
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
