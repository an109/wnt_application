import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../wallet/data/data_source/wallet_api_service.dart';

/// The user picks Wallet or Razorpay, then pays via the Razorpay native checkout.
class PaymentSection extends StatefulWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;

  final double amountInr;
  final Map<String, dynamic> formData;
  final VoidCallback onBack;
  final VoidCallback onPaymentSuccess;

  const PaymentSection({
    Key? key,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    required this.amountInr,
    required this.formData,
    required this.onBack,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xff0D47A1);

  late final Razorpay _razorpay;
  String? _selectedMethod; // 'wallet' | 'razorpay'
  bool _isProcessing = false;
  bool _isExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isActive;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isExpanded) _animationController.value = 1.0;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
  }

  @override
  void didUpdateWidget(covariant PaymentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto expand when this step becomes active, collapse when it isn't.
    if (widget.isActive != oldWidget.isActive) {
      _isExpanded = widget.isActive;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.w(8),
            offset: Offset(0, context.h(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (widget.isCompleted || widget.isActive) _toggleExpand();
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
              padding: EdgeInsets.all(context.w(12)),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? const Color(0xffE3F2FD)
                    : widget.isCompleted
                    ? Colors.green.shade50
                    : Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: context.w(24),
                    height: context.w(24),
                    decoration: BoxDecoration(
                      color: widget.isCompleted
                          ? Colors.green
                          : widget.isActive
                          ? _navy
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.isCompleted
                          ? Icon(Icons.check, size: context.iconXSmall, color: Colors.white)
                          : Text(
                        '${widget.stepNumber}',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  const Expanded(
                    child: Text(
                      'Make Payment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(Icons.keyboard_arrow_down,
                        size: context.iconMedium, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _heightAnimation,
            axisAlignment: -1.0,
            child: ClipRect(child: _buildBody()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.all(context.w(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Payment Method',
            style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: context.h(12)),
          _buildMethodTile(
            value: 'wallet',
            icon: Icons.account_balance_wallet_outlined,
            title: 'My Wallet',
            subtitle: 'Pay using your wallet balance',
          ),
          SizedBox(height: context.h(8)),
          _buildMethodTile(
            value: 'razorpay',
            icon: Icons.payment,
            title: 'Razorpay',
            subtitle: 'Cards, UPI, Net Banking, Wallets',
          ),
          SizedBox(height: context.h(16)),
          Container(
            padding: EdgeInsets.all(context.w(10)),
            decoration: BoxDecoration(
              color: const Color(0xffF1F5FF),
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount payable',
                    style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600)),
                Text(
                  '${widget.amountInr.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: context.fs(14),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xffFF6B00),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(16)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : widget.onBack,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _navy),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(6))),
                    padding: EdgeInsets.symmetric(vertical: context.h(10)),
                  ),
                  child: Text('BACK',
                      style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w600,
                          color: _navy)),
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(6))),
                    padding: EdgeInsets.symmetric(vertical: context.h(10)),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                    width: context.w(16),
                    height: context.w(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : Text(
                    'PAY ${widget.amountInr.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: context.fs(11),
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: EdgeInsets.all(context.w(12)),
        decoration: BoxDecoration(
          color: isSelected ? _navy.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(context.r(6)),
          border: Border.all(
            color: isSelected ? _navy : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.iconMedium, color: isSelected ? _navy : Colors.grey.shade600),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: context.fs(12), fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: context.fs(10), color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: context.iconMedium, color: _navy),
          ],
        ),
      ),
    );
  }

  void _snack(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Pays from the wallet if its balance covers the amount (uses
  /// [Urls.walletBalance]). There is no debit endpoint, so a sufficient
  /// balance is treated as a successful payment.
  // Future<void> _payWithWallet() async {
  //   // Wallet payment requires a logged-in user.
  //   if (!di.sl<PreferencesManager>().isLoggedIn()) {
  //     _snack('Please log in to pay with your wallet.');
  //     return;
  //   }
  //
  //   setState(() => _isProcessing = true);
  //   try {
  //     final response = await di.sl<WalletApiService>().getWalletBalance();
  //     final data = (response.data as Map).cast<String, dynamic>();
  //     final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
  //     final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;
  //
  //     if (!mounted) return;
  //     setState(() => _isProcessing = false);
  //
  //     if (balance >= widget.amountInr) {
  //       widget.onPaymentSuccess();
  //     } else {
  //       _snack(
  //         'Insufficient wallet balance (${balance.toStringAsFixed(2)} available). '
  //             'Please choose CCAvenue.',
  //       );
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() => _isProcessing = false);
  //     _snack('Could not fetch wallet balance. Please try again.');
  //   }
  // }
  Future<void> _payWithWallet() async {
    if (!di.sl<PreferencesManager>().isLoggedIn()) {
      _snack('Please log in to pay with your wallet.');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await di.sl<WalletApiService>().getWalletBalance();
      final data = (response.data as Map).cast<String, dynamic>();
      final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
      final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (balance >= widget.amountInr) {
        await _completePaymentOnBackend(
          paymentReference: 'WALLET${DateTime.now().millisecondsSinceEpoch}',
          paymentMode: 'wallet',
        );
      } else {
        _snack(
          'Insufficient wallet balance (${balance.toStringAsFixed(2)} available). '
              'Please choose Razorpay.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Could not fetch wallet balance. Please try again.');
    }
  }
  Future<void> _pay() async {
    if (_selectedMethod == null) {
      _snack('Please select a payment method');
      return;
    }

    if (_selectedMethod == 'wallet') {
      await _payWithWallet();
      return;
    }

    await _initiateRazorpayPayment();
  }

  // ----- Razorpay flow -----
  Future<void> _initiateRazorpayPayment() async {
    setState(() => _isProcessing = true);
    try {
      final amount = double.parse(widget.amountInr.toStringAsFixed(2));
      final phone = (widget.formData['phone'] ?? '')
          .toString()
          .replaceAll(RegExp(r'[^0-9]'), '');

      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': amount,
          'currency': 'INR',
          'reference_id': 'visa_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final orderId = response.data['order_id'];
      final keyId = response.data['key_id'];
      print("Razorpay Key: $keyId");

      final firstName = (widget.formData['firstName'] ?? '').toString();
      final lastName = (widget.formData['lastName'] ?? '').toString();

      final options = {
        'key': keyId,
        'amount': (amount * 100).toInt(),
        'currency': 'INR',
        'name': 'WanderNova',
        'description': 'Visa Application',
        'order_id': orderId,
        'prefill': {
          'name': '$firstName $lastName'.trim(),
          'email': (widget.formData['email'] ?? '').toString(),
          'contact': phone,
        },
        'theme': {'color': '#0D47A1'},
      };

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _razorpay.open(options);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      print('Razorpay order error: ${e.message}');
      _snack('Could not create payment order. Please try again.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Could not start payment. Please try again.');
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) {
    _completePaymentOnBackend(
      paymentReference: response.paymentId ?? '',
      paymentMode: 'razorpay',
    );
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _snack('Payment failed: ${response.message ?? 'Please try again.'}');
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    print('Razorpay external wallet: ${response.walletName}');
  }

  /// Marks the visa application as paid on the backend
  /// (`/visa-application/{id}/complete-payment/`) after money has actually
  /// moved (Razorpay or wallet). If this call fails the payment itself has
  /// still succeeded, so we surface the reference for support instead of
  /// silently retrying (which would risk charging the user twice).
  Future<void> _completePaymentOnBackend({
    required String paymentReference,
    required String paymentMode,
  }) async {
    final applicationId = widget.formData['applicationId'];
    if (applicationId == null) {
      widget.onPaymentSuccess();
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(
        Urls.visaCompletePayment(applicationId),
        data: {
          'user_email': (widget.formData['email'] ??
                  widget.formData['contactEmail'] ??
                  '')
              .toString(),
          'payment_reference': paymentReference,
          'payment_mode': paymentMode,
        },
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      if (body['success'] == true) {
        widget.onPaymentSuccess();
      } else {
        _snack(
          'Payment succeeded but the application could not be updated. '
          'Please contact support with reference: $paymentReference',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack(
        'Payment succeeded but the application could not be updated. '
        'Please contact support with reference: $paymentReference',
      );
    }
  }
}