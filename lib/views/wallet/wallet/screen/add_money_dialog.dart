import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/constants/urls.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../flight_payment/data/ccavenue_service.dart';
import '../../../flight_payment/presentation/screen/ccavenue_payment_page.dart';

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
  String _selectedPaymentMethod = 'CCavenue';
  double? _selectedQuickAmount;

  final CCAvenueService _ccavenueService = CCAvenueService();
  bool _isProcessing = false;

  final List<double> _quickAmounts = [500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose(); // Proper cleanup
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
                'You will be redirected to CCavenue\'s secure checkout (INR).',
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

  /// Recharges the wallet via the CCAvenue hosted gateway. On success the
  /// parent's [onConfirm] runs (refreshes balance) and the dialog closes.
  Future<void> _pay(double amount) async {
    final prefs = di.sl<PreferencesManager>();

    // Adding money to the wallet requires a logged-in user.
    if (!prefs.isLoggedIn()) {
      _snack('Please log in to add money to your wallet.');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Backend requires a short order_id (CCAvenue limits length ~30 chars).
      final orderId = '${DateTime.now().millisecondsSinceEpoch}';
      // final orderId = 'WTXW${DateTime.now().millisecondsSinceEpoch}';
      final payable = double.parse(amount.toStringAsFixed(2));

      final userData = prefs.getUserData() ?? {};
      final fullName = (userData['userName'] ??
              userData['name'] ??
              userData['first_name'] ??
              prefs.getString('user_name') ??
              '')
          .toString()
          .trim();
      final parts = fullName.isEmpty ? <String>[] : fullName.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final email = (userData['email'] ?? prefs.getString('user_email') ?? '')
          .toString();
      final phone = (userData['phone'] ??
              userData['mobile'] ??
              userData['phone_number'] ??
              '')
          .toString()
          .replaceAll(RegExp(r'[^0-9]'), '');

      final session = await _ccavenueService.createCheckout(
        orderId: orderId,
        amount: payable,
        currency: 'INR',
        transactionType: 'wallet',
        userId: prefs.getUserId(),
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        successUrl: Urls.ccavenueSuccessUrl,
        failureUrl: Urls.ccavenueFailureUrl,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final result = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          builder: (_) => CCAvenuePaymentPage(
            service: _ccavenueService,
            session: session,
          ),
        ),
      );

      if (!mounted) return;
      switch (result) {
        case PaymentResult.success:
          // Let the parent record the top-up / refresh the balance, then close.
          widget.onConfirm(payable, _selectedPaymentMethod);
          Navigator.pop(context);
          break;
        case PaymentResult.failure:
          _snack('Payment failed. Please try again.');
          break;
        case PaymentResult.cancelled:
        case null:
          _snack('Payment cancelled.', color: Colors.grey.shade700);
          break;
      }
    } on CCAvenueException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _snack('Could not start payment. Please try again.');
    }
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
                  'CCavenue',
                  style: TextStyle(
                    fontSize: context.bodyMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'UPI, Card, Net Banking (INR)',
                  style: TextStyle(
                    fontSize: context.bodySmall,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Radio<String>(
            value: 'CCavenue',
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