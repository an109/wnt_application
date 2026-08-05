import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;

class AddMoneyDialog extends StatefulWidget {
  final Function(double amount, String paymentMethod) onConfirm;

  const AddMoneyDialog({
    super.key, // Allow external key assignment
    required this.onConfirm,
  });

  @override
  State<AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends State<AddMoneyDialog> {
  // Use local TextEditingController without GlobalKey
  late final TextEditingController _amountController;
  String _selectedPaymentMethod = 'Razorpay';
  double? _selectedQuickAmount;

  late final Razorpay _razorpay;
  bool _isProcessing = false;

  // Set when a Razorpay checkout is opened, so the async success handler knows
  // which top-up it is confirming.
  String _reference = '';
  double _payableAmount = 0;

  final List<double> _quickAmounts = [500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
  }

  @override
  void dispose() {
    _amountController.dispose(); // Proper cleanup
    _razorpay.clear();
    super.dispose();
  }

  void _onQuickAmountSelected(double amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  void _onAmountChanged(String value) {
    setState(() {
      _selectedQuickAmount = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadiusLarge),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: context.isDesktop ? 500 : double.infinity,
          maxHeight: context.hp(70),
        ),
        padding: context.responsivePadding,
        child: SingleChildScrollView(  // 👈 Add this to make content scrollable
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add money / Recharge',
                    style: TextStyle(
                      fontSize: context.titleLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              SizedBox(height: context.gapLarge),

              // Amount Input
              Text(
                'Amount (₹ INR)',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: context.gapSmall),

              TextField(
                controller: _amountController,
                onChanged: _onAmountChanged,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g. 500',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: context.bodyLarge,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.gapMedium,
                    vertical: context.gapMedium,
                  ),
                ),
              ),

              SizedBox(height: context.gapMedium),

              // Quick Amount Buttons
              Wrap(
                spacing: context.gapSmall,
                runSpacing: context.gapSmall,
                children: _quickAmounts.map((amt) {
                  final isSelected = _selectedQuickAmount == amt;
                  return ChoiceChip(
                    key: ValueKey('quick_amount_$amt'),
                    label: Text('₹${amt.toInt()}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _onQuickAmountSelected(amt);
                    },
                    selectedColor: Colors.red.shade50,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.red.shade700 : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: context.gapLarge),

              // Payment Method
              Text(
                'Payment method',
                style: TextStyle(
                  fontSize: context.bodyMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: context.gapSmall),

              _buildPaymentMethodCard(),

              SizedBox(height: context.gapMedium),

              Text(
                'You will be redirected to Razorpay\'s secure checkout (INR).',
                style: TextStyle(
                  fontSize: context.bodySmall,
                  color: Colors.grey.shade600,
                ),
              ),

              SizedBox(height: context.gapXLarge),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: context.gapMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: context.bodyMedium),
                      ),
                    ),
                  ),

                  SizedBox(width: context.gapMedium),

                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (amount > 0 && !_isProcessing)
                          ? () => _pay(amount)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: context.gapMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.borderRadiusMedium),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Pay ₹${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: context.bodyMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final amount = double.tryParse(_amountController.text) ?? 0;
  //
  //   return Dialog(
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(context.borderRadiusLarge),
  //     ),
  //     child: Container(
  //       constraints: BoxConstraints(
  //         maxWidth: context.isDesktop ? 500 : double.infinity,
  //         maxHeight: context.hp(70),
  //       ),
  //       padding: context.responsivePadding,
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Header
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'Add money / Recharge',
  //                 style: TextStyle(
  //                   fontSize: context.titleLarge,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               IconButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 icon: const Icon(Icons.close),
  //                 padding: EdgeInsets.zero,
  //                 constraints: const BoxConstraints(),
  //                 // No key needed for simple IconButton
  //               ),
  //             ],
  //           ),
  //
  //           SizedBox(height: context.gapLarge),
  //
  //           // Amount Input
  //           Text(
  //             'Amount (₹ INR)',
  //             style: TextStyle(
  //               fontSize: context.bodyMedium,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //
  //           SizedBox(height: context.gapSmall),
  //
  //           TextField(
  //             controller: _amountController,
  //             onChanged: _onAmountChanged,
  //             keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //             inputFormatters: [
  //               FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  //             ],
  //             decoration: InputDecoration(
  //               hintText: 'e.g. 500',
  //               prefixText: '₹ ',
  //               prefixStyle: TextStyle(
  //                 fontSize: context.bodyLarge,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(context.borderRadiusMedium),
  //               ),
  //               contentPadding: EdgeInsets.symmetric(
  //                 horizontal: context.gapMedium,
  //                 vertical: context.gapMedium,
  //               ),
  //             ),
  //             // No key - TextField doesn't need GlobalKey unless form validation
  //           ),
  //
  //           SizedBox(height: context.gapMedium),
  //
  //           // Quick Amount Buttons - Use ValueKey for uniqueness
  //           Wrap(
  //             spacing: context.gapSmall,
  //             runSpacing: context.gapSmall,
  //             children: _quickAmounts.map((amt) {
  //               final isSelected = _selectedQuickAmount == amt;
  //               return ChoiceChip(
  //                 key: ValueKey('quick_amount_$amt'), // Unique key per amount
  //                 label: Text('₹${amt.toInt()}'),
  //                 selected: isSelected,
  //                 onSelected: (selected) {
  //                   if (selected) _onQuickAmountSelected(amt);
  //                 },
  //                 selectedColor: Colors.red.shade50,
  //                 labelStyle: TextStyle(
  //                   color: isSelected ? Colors.red.shade700 : Colors.black87,
  //                   fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //                 ),
  //               );
  //             }).toList(),
  //           ),
  //
  //           SizedBox(height: context.gapLarge),
  //
  //           // Payment Method
  //           Text(
  //             'Payment method',
  //             style: TextStyle(
  //               fontSize: context.bodyMedium,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //
  //           SizedBox(height: context.gapSmall),
  //
  //           _buildPaymentMethodCard(),
  //
  //           SizedBox(height: context.gapMedium),
  //
  //           Text(
  //             'You will be redirected to CCavenue\'s secure checkout (INR).',
  //             style: TextStyle(
  //               fontSize: context.bodySmall,
  //               color: Colors.grey.shade600,
  //             ),
  //           ),
  //
  //           SizedBox(height: context.gapXLarge),
  //
  //           // Actions
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: OutlinedButton(
  //                   onPressed: () => Navigator.pop(context),
  //                   style: OutlinedButton.styleFrom(
  //                     padding: EdgeInsets.symmetric(vertical: context.gapMedium),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(context.borderRadiusMedium),
  //                     ),
  //                   ),
  //                   child: Text(
  //                     'Cancel',
  //                     style: TextStyle(fontSize: context.bodyMedium),
  //                   ),
  //                 ),
  //               ),
  //
  //               SizedBox(width: context.gapMedium),
  //
  //               Expanded(
  //                 flex: 2,
  //                 child: ElevatedButton(
  //                   onPressed: amount > 0
  //                       ? () {
  //                     widget.onConfirm(amount, _selectedPaymentMethod);
  //                     Navigator.pop(context);
  //                   }
  //                       : null,
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.red.shade600,
  //                     foregroundColor: Colors.white,
  //                     padding: EdgeInsets.symmetric(vertical: context.gapMedium),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(context.borderRadiusMedium),
  //                     ),
  //                     elevation: 0,
  //                   ),
  //                   child: Text(
  //                     'Pay ₹${amount.toStringAsFixed(2)}',
  //                     style: TextStyle(
  //                       fontSize: context.bodyMedium,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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

  /// Recharges the wallet via Razorpay's native checkout. On a confirmed
  /// credit the parent's [onConfirm] runs (refreshes balance) and the dialog
  /// closes.
  ///
  /// KNOWN BACKEND GAP — the wallet is NOT yet credited automatically for
  /// Razorpay top-ups. `/wallet/verify-payment/` only knows how to settle
  /// Nomod checkouts (it needs `nomod_checkout_id`), and CCAvenue top-ups are
  /// credited out-of-band by CCAvenue's own server-to-server response handler
  /// (`ccavenue_payments/views.py::_credit_wallet_if_needed`). There is no
  /// equivalent Razorpay branch, so [_creditWallet] below will normally fail.
  /// The payment itself is still signature-verified server-side and recorded
  /// as a paid RazorpayTransaction, and the user is shown their reference for
  /// support — we never report a credit that did not happen. Wiring a
  /// Razorpay branch into the wallet backend will make this flow complete
  /// with no further changes here.
  Future<void> _pay(double amount) async {
    final prefs = di.sl<PreferencesManager>();

    if (!prefs.isLoggedIn()) {
      _snack('Please log in to add money to your wallet.');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final payable = double.parse(amount.toStringAsFixed(2));
      // Short reference (Razorpay receipts are capped at 40 chars) that ties
      // the gateway order to this top-up.
      final reference = 'WTX${DateTime.now().millisecondsSinceEpoch}';

      final dio = di.sl<DioClient>().instance;
      final response = await dio.post(
        Urls.razorpayCreateOrder,
        data: {
          'amount': payable,
          'currency': 'INR',
          'reference_id': reference,
          'transaction_type': 'wallet',
        },
      );

      final orderId = response.data['order_id'];
      final keyId = response.data['key_id'];

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _reference = reference;
        _payableAmount = payable;
      });

      final userData = prefs.getUserData() ?? {};
      _razorpay.open({
        'key': keyId,
        'amount': (payable * 100).toInt(),
        'currency': 'INR',
        'name': 'WanderNova',
        'description': 'Wallet Top-up',
        'order_id': orderId,
        'prefill': {
          'name': '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim(),
          'email': (userData['email'] ?? '').toString(),
          'contact': (userData['phone_number'] ?? '').toString(),
        },
        'theme': {'color': '#E53935'},
      });
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

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    final dio = di.sl<DioClient>().instance;

    // Step 1: verify the signature server-side. Until this passes the payment
    // is not trustworthy, so nothing is credited on its basis.
    try {
      final verify = await dio.post(
        Urls.razorpayVerify,
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'reference_id': _reference,
        },
      );
      if (verify.data['success'] != true) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _snack(
          'Payment could not be verified. If money was deducted, contact '
          'support with reference: ${response.paymentId ?? _reference}',
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack(
        'Payment could not be verified. If money was deducted, contact '
        'support with reference: ${response.paymentId ?? _reference}',
      );
      return;
    }

    // Step 2: ask the wallet backend to credit the balance. See the note on
    // [_pay] — this is expected to fail until the backend grows a Razorpay
    // branch, which is why the failure path stays explicit rather than
    // optimistically closing the dialog.
    final credited = await _creditWallet();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (credited) {
      widget.onConfirm(_payableAmount, _selectedPaymentMethod);
      Navigator.pop(context);
    } else {
      _snack(
        'Payment received, but your wallet balance has not updated yet. '
        'Please contact support with reference: '
        '${response.paymentId ?? _reference}',
      );
    }
  }

  /// Attempts to settle the top-up on the wallet backend. Returns true only
  /// when the backend confirms the balance was actually credited.
  Future<bool> _creditWallet() async {
    try {
      final dio = di.sl<DioClient>().instance;
      final res = await dio.post(
        Urls.walletVerifyPayment,
        data: {'reference': _reference},
      );
      final body = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      return body['success'] == true;
    } catch (e) {
      print('Wallet credit after Razorpay top-up failed: $e');
      return false;
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _snack('Payment failed: ${response.message ?? 'Please try again.'}');
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    print('Razorpay external wallet: ${response.walletName}');
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      key: const ValueKey('payment_method_card'), // Unique key for this card
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(context.borderRadiusMedium),
        color: Colors.red.shade50,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.gapSmall),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.borderRadiusSmall),
            ),
            child: Icon(
              Icons.payment,
              color: Colors.red.shade600,
              size: context.iconMedium,
            ),
          ),
          SizedBox(width: context.gapMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Razorpay',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'UPI, Card, Net Banking, Wallets (INR)',
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Radio<String>(
            value: 'Razorpay',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPaymentMethod = value);
              }
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}