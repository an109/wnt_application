// import 'package:flutter/material.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
//
// import '../../../../core/constants/urls.dart';
// import '../../../../core/utils/storage/shared_preference.dart';
// import '../../../../injection_container.dart' as di;
// import '../../../flight_payment/data/ccavenue_service.dart';
// import '../../../flight_payment/presentation/screen/ccavenue_payment_page.dart';
// import '../../../wallet/data/data_source/wallet_api_service.dart';
//
// /// The user picks Wallet or CCAvenue, then pays via the CCAvenue hosted gateway.
// class PaymentSection extends StatefulWidget {
//   final int stepNumber;
//   final bool isCompleted;
//   final bool isActive;
//
//   final double amountInr;
//   final Map<String, dynamic> formData;
//   final VoidCallback onBack;
//   final VoidCallback onPaymentSuccess;
//
//   const PaymentSection({
//     Key? key,
//     required this.stepNumber,
//     required this.isCompleted,
//     required this.isActive,
//     required this.amountInr,
//     required this.formData,
//     required this.onBack,
//     required this.onPaymentSuccess,
//   }) : super(key: key);
//
//   @override
//   State<PaymentSection> createState() => _PaymentSectionState();
// }
//
// class _PaymentSectionState extends State<PaymentSection>
//     with SingleTickerProviderStateMixin {
//   static const _navy = Color(0xff0D47A1);
//
//   final CCAvenueService _ccavenueService = CCAvenueService();
//   String? _selectedMethod; // 'wallet' | 'ccavenue'
//   bool _isProcessing = false;
//   bool _isExpanded = false;
//
//   late AnimationController _animationController;
//   late Animation<double> _heightAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _isExpanded = widget.isActive;
//
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//     if (_isExpanded) _animationController.value = 1.0;
//   }
//
//   @override
//   void didUpdateWidget(covariant PaymentSection oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Auto expand when this step becomes active, collapse when it isn't.
//     if (widget.isActive != oldWidget.isActive) {
//       _isExpanded = widget.isActive;
//       if (_isExpanded) {
//         _animationController.forward();
//       } else {
//         _animationController.reverse();
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   void _toggleExpand() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//       if (_isExpanded) {
//         _animationController.forward();
//       } else {
//         _animationController.reverse();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(context.r(8)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: context.w(8),
//             offset: Offset(0, context.h(2)),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             onTap: () {
//               if (widget.isCompleted || widget.isActive) _toggleExpand();
//             },
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
//             child: Container(
//               padding: EdgeInsets.all(context.w(12)),
//               decoration: BoxDecoration(
//                 color: widget.isActive
//                     ? const Color(0xffE3F2FD)
//                     : widget.isCompleted
//                     ? Colors.green.shade50
//                     : Colors.white,
//                 borderRadius:
//                 const BorderRadius.vertical(top: Radius.circular(8)),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: context.w(24),
//                     height: context.w(24),
//                     decoration: BoxDecoration(
//                       color: widget.isCompleted
//                           ? Colors.green
//                           : widget.isActive
//                           ? _navy
//                           : Colors.grey.shade300,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Center(
//                       child: widget.isCompleted
//                           ? Icon(Icons.check, size: context.iconXSmall, color: Colors.white)
//                           : Text(
//                         '${widget.stepNumber}',
//                         style: TextStyle(
//                           fontSize: context.fs(11),
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: context.w(8)),
//                   const Expanded(
//                     child: Text(
//                       'Make Payment',
//                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                   AnimatedRotation(
//                     turns: _isExpanded ? 0.5 : 0.0,
//                     duration: const Duration(milliseconds: 200),
//                     curve: Curves.easeInOut,
//                     child: Icon(Icons.keyboard_arrow_down,
//                         size: context.iconMedium, color: Colors.grey.shade600),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           SizeTransition(
//             sizeFactor: _heightAnimation,
//             axisAlignment: -1.0,
//             child: ClipRect(child: _buildBody()),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     return Padding(
//       padding: EdgeInsets.all(context.w(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Select Payment Method',
//             style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600),
//           ),
//           SizedBox(height: context.h(12)),
//           _buildMethodTile(
//             value: 'wallet',
//             icon: Icons.account_balance_wallet_outlined,
//             title: 'My Wallet',
//             subtitle: 'Pay using your wallet balance',
//           ),
//           SizedBox(height: context.h(8)),
//           _buildMethodTile(
//             value: 'ccavenue',
//             icon: Icons.credit_card,
//             title: 'CCAvenue',
//             subtitle: 'Cards, UPI, Net Banking',
//           ),
//           SizedBox(height: context.h(16)),
//           Container(
//             padding: EdgeInsets.all(context.w(10)),
//             decoration: BoxDecoration(
//               color: const Color(0xffF1F5FF),
//               borderRadius: BorderRadius.circular(context.r(6)),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Amount payable',
//                     style: TextStyle(fontSize: context.fs(11), fontWeight: FontWeight.w600)),
//                 Text(
//                   '${widget.amountInr.toStringAsFixed(2)}',
//                   style: TextStyle(
//                     fontSize: context.fs(14),
//                     fontWeight: FontWeight.w800,
//                     color: const Color(0xffFF6B00),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: context.h(16)),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: _isProcessing ? null : widget.onBack,
//                   style: OutlinedButton.styleFrom(
//                     side: const BorderSide(color: _navy),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(context.r(6))),
//                     padding: EdgeInsets.symmetric(vertical: context.h(10)),
//                   ),
//                   child: Text('BACK',
//                       style: TextStyle(
//                           fontSize: context.fs(11),
//                           fontWeight: FontWeight.w600,
//                           color: _navy)),
//                 ),
//               ),
//               SizedBox(width: context.w(8)),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: _isProcessing ? null : _pay,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _navy,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(context.r(6))),
//                     padding: EdgeInsets.symmetric(vertical: context.h(10)),
//                   ),
//                   child: _isProcessing
//                       ? SizedBox(
//                     width: context.w(16),
//                     height: context.w(16),
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor:
//                       const AlwaysStoppedAnimation(Colors.white),
//                     ),
//                   )
//                       : Text(
//                     'PAY ${widget.amountInr.toStringAsFixed(2)}',
//                     style: TextStyle(
//                         fontSize: context.fs(11),
//                         fontWeight: FontWeight.w700,
//                         color: Colors.white),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMethodTile({
//     required String value,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//   }) {
//     final isSelected = _selectedMethod == value;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedMethod = value),
//       child: Container(
//         padding: EdgeInsets.all(context.w(12)),
//         decoration: BoxDecoration(
//           color: isSelected ? _navy.withOpacity(0.05) : Colors.grey.shade50,
//           borderRadius: BorderRadius.circular(context.r(6)),
//           border: Border.all(
//             color: isSelected ? _navy : Colors.grey.shade200,
//             width: isSelected ? 1.5 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, size: context.iconMedium, color: isSelected ? _navy : Colors.grey.shade600),
//             SizedBox(width: context.w(10)),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: TextStyle(
//                           fontSize: context.fs(12), fontWeight: FontWeight.w600)),
//                   Text(subtitle,
//                       style: TextStyle(
//                           fontSize: context.fs(10), color: Colors.grey.shade600)),
//                 ],
//               ),
//             ),
//             if (isSelected)
//               Icon(Icons.check_circle, size: context.iconMedium, color: _navy),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _snack(String message, {Color color = Colors.red}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   /// Pays from the wallet if its balance covers the amount (uses
//   /// [Urls.walletBalance]). There is no debit endpoint, so a sufficient
//   /// balance is treated as a successful payment.
//   Future<void> _payWithWallet() async {
//     // Wallet payment requires a logged-in user.
//     if (!di.sl<PreferencesManager>().isLoggedIn()) {
//       _snack('Please log in to pay with your wallet.');
//       return;
//     }
//
//     setState(() => _isProcessing = true);
//     try {
//       final response = await di.sl<WalletApiService>().getWalletBalance();
//       final data = (response.data as Map).cast<String, dynamic>();
//       final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
//       final balance = double.tryParse('${wallet['balance'] ?? 0}') ?? 0;
//
//       if (!mounted) return;
//       setState(() => _isProcessing = false);
//
//       if (balance >= widget.amountInr) {
//         widget.onPaymentSuccess();
//       } else {
//         _snack(
//           'Insufficient wallet balance (${balance.toStringAsFixed(2)} available). '
//               'Please choose CCAvenue.',
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isProcessing = false);
//       _snack('Could not fetch wallet balance. Please try again.');
//     }
//   }
//
//   Future<void> _pay() async {
//     if (_selectedMethod == null) {
//       _snack('Please select a payment method');
//       return;
//     }
//     if (_selectedMethod == 'wallet') {
//       await _payWithWallet();
//       return;
//     }
//
//     // ----- CCAvenue hosted-checkout flow -----
//     setState(() => _isProcessing = true);
//     try {
//       // Backend requires a short order_id (CCAvenue limits length ~30 chars).
//       final orderId = '${DateTime.now().millisecondsSinceEpoch}';
//       // final orderId = 'WTXV${DateTime.now().millisecondsSinceEpoch}';
//       final amount = double.parse(widget.amountInr.toStringAsFixed(2));
//       final phone = (widget.formData['phone'] ?? '')
//           .toString()
//           .replaceAll(RegExp(r'[^0-9]'), '');
//
//       final session = await _ccavenueService.createCheckout(
//         orderId: orderId,
//         amount: amount,
//         currency: 'INR',
//         transactionType: 'visa',
//         firstName: (widget.formData['firstName'] ?? '').toString(),
//         lastName: (widget.formData['lastName'] ?? '').toString(),
//         email: (widget.formData['email'] ?? '').toString(),
//         phone: phone,
//         successUrl: Urls.ccavenueSuccessUrl,
//         failureUrl: Urls.ccavenueFailureUrl,
//       );
//
//       if (!mounted) return;
//       setState(() => _isProcessing = false);
//
//       final result = await Navigator.of(context).push<PaymentResult>(
//         MaterialPageRoute(
//           builder: (_) => CCAvenuePaymentPage(
//             service: _ccavenueService,
//             session: session,
//           ),
//         ),
//       );
//
//       if (!mounted) return;
//       switch (result) {
//         case PaymentResult.success:
//           widget.onPaymentSuccess();
//           break;
//         case PaymentResult.failure:
//           _snack('Payment failed. Please try again.');
//           break;
//         case PaymentResult.cancelled:
//         case null:
//           _snack('Payment cancelled.', color: Colors.grey.shade700);
//           break;
//       }
//     } on CCAvenueException catch (e) {
//       if (!mounted) return;
//       setState(() => _isProcessing = false);
//       _snack(e.message);
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isProcessing = false);
//       _snack('Could not start payment. Please try again.');
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../../../../core/constants/urls.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../flight_payment/data/ccavenue_service.dart';
import '../../../flight_payment/presentation/screen/ccavenue_payment_page.dart';
import '../../../wallet/data/data_source/wallet_api_service.dart';

/// The user picks Wallet or CCAvenue, then pays via the CCAvenue hosted gateway.
class PaymentSection extends StatefulWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;

  final double amountInr;
  final Map<String, dynamic> formData;
  final VoidCallback onBack;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentComplete;

  const PaymentSection({
    Key? key,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    required this.amountInr,
    required this.formData,
    required this.onBack,
    required this.onPaymentSuccess,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xff0D47A1);

  final CCAvenueService _ccavenueService = CCAvenueService();
  String? _selectedMethod; // 'wallet' | 'ccavenue'
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
            value: 'ccavenue',
            icon: Icons.credit_card,
            title: 'CCAvenue',
            subtitle: 'Cards, UPI, Net Banking',
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
        // ✅ Payment successful - trigger API with 'completed' status
        widget.onPaymentComplete(); // This will call the API with payment_completed status
        widget.onPaymentSuccess();
      } else {
        _snack(
          'Insufficient wallet balance (${balance.toStringAsFixed(2)} available). '
              'Please choose CCAvenue.',
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

    // ----- CCAvenue hosted-checkout flow -----
    setState(() => _isProcessing = true);
    try {
      // Backend requires a short order_id (CCAvenue limits length ~30 chars).
      final orderId = '${DateTime.now().millisecondsSinceEpoch}';
      // final orderId = 'WTXV${DateTime.now().millisecondsSinceEpoch}';
      final amount = double.parse(widget.amountInr.toStringAsFixed(2));
      final phone = (widget.formData['phone'] ?? '')
          .toString()
          .replaceAll(RegExp(r'[^0-9]'), '');

      final session = await _ccavenueService.createCheckout(
        orderId: orderId,
        amount: amount,
        currency: 'INR',
        transactionType: 'visa',
        firstName: (widget.formData['firstName'] ?? '').toString(),
        lastName: (widget.formData['lastName'] ?? '').toString(),
        email: (widget.formData['email'] ?? '').toString(),
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
          widget.onPaymentComplete();
          widget.onPaymentSuccess();
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
}