// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
// import 'package:wander_nova/core/resources/app_colours.dart';
// import 'package:wander_nova/core/services/payment_gateway_service.dart';
// import 'package:wander_nova/core/utils/storage/shared_preference.dart';
// import 'package:wander_nova/injection_container.dart';
//
// import '../../../wallet/wallet/screen/checkout/checkout_ui.dart';
// import '../../data/nomod_checkout_service.dart';
// import 'nomod_checkout_screen.dart';
//
// /// Nomod payment method tiles for UAE users. Drop this into any payment
// /// screen's column in place of the Razorpay accordion sections.
// ///
// /// [onPaymentComplete] is called with the [NomodPaymentResult] after a
// /// successful Nomod checkout. The caller handles StartPay / booking
// /// confirmation exactly as it does for Razorpay.
// class NomodPaymentMethods extends StatelessWidget {
//   final double amount;
//   final String currency;
//   final String referenceId;
//   final String transactionType;
//   final String? email;
//   final String? phone;
//   final String? customerName;
//   final bool processing;
//   final Future<void> Function(NomodPaymentResult result) onPaymentComplete;
//   final void Function(String error) onError;
//
//   const NomodPaymentMethods({
//     super.key,
//     required this.amount,
//     required this.referenceId,
//     required this.transactionType,
//     required this.onPaymentComplete,
//     required this.onError,
//     this.currency = 'AED',
//     this.email,
//     this.phone,
//     this.customerName,
//     this.processing = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         for (final method in PaymentGatewayService.nomodMethods) ...[
//           _NomodMethodTile(
//             method: method,
//             processing: processing,
//             onTap: () => _launchNomodCheckout(context, method),
//           ),
//           SizedBox(height: context.h(8)),
//         ],
//       ],
//     );
//   }
//
//   Future<void> _launchNomodCheckout(
//       BuildContext context, NomodPaymentMethod method) async {
//     if (processing) return;
//
//     final service = NomodCheckoutService();
//     final userId = sl<PreferencesManager>().getUserId();
//
//     String methodKey;
//     switch (method) {
//       case NomodPaymentMethod.tamara:
//         methodKey = 'tamara';
//         break;
//       case NomodPaymentMethod.tabby:
//         methodKey = 'tabby';
//         break;
//       case NomodPaymentMethod.googlePay:
//         methodKey = 'google_pay';
//         break;
//       case NomodPaymentMethod.applePay:
//         methodKey = 'apple_pay';
//         break;
//       case NomodPaymentMethod.card:
//         methodKey = 'card';
//         break;
//     }
//
//     // Hide Apple Pay on Android, Google Pay on iOS
//     if (method == NomodPaymentMethod.applePay && !Platform.isIOS) return;
//     if (method == NomodPaymentMethod.googlePay && !Platform.isAndroid) return;
//
//     try {
//       final checkout = await service.createCheckout(
//         amount: amount,
//         currency: currency,
//         referenceId: referenceId,
//         transactionType: transactionType,
//         paymentMethod: methodKey,
//         email: email,
//         phone: phone,
//         customerName: customerName,
//         userId: userId,
//       );
//
//       if (!context.mounted) return;
//
//       final result = await Navigator.push<NomodPaymentResult>(
//         context,
//         MaterialPageRoute(
//           builder: (_) => NomodCheckoutScreen(
//             checkoutUrl: checkout.checkoutUrl,
//             checkoutId: checkout.checkoutId,
//             referenceId: referenceId,
//           ),
//         ),
//       );
//
//       if (result != null && result.success) {
//         await onPaymentComplete(result);
//       }
//     } on NomodCheckoutException catch (e) {
//       onError(e.message);
//     } catch (e) {
//       onError('Could not start payment. Please try again.');
//     }
//   }
// }
//
// class _NomodMethodTile extends StatelessWidget {
//   final NomodPaymentMethod method;
//   final bool processing;
//   final VoidCallback onTap;
//
//   const _NomodMethodTile({
//     required this.method,
//     required this.processing,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // Hide Apple Pay on Android, Google Pay on iOS
//     if (method == NomodPaymentMethod.applePay && !Platform.isIOS) {
//       return const SizedBox.shrink();
//     }
//     if (method == NomodPaymentMethod.googlePay && !Platform.isAndroid) {
//       return const SizedBox.shrink();
//     }
//
//     return GestureDetector(
//       onTap: processing ? null : onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: context.w(14),
//           vertical: context.h(14),
//         ),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(context.r(12)),
//           border: Border.all(color: const Color(0xFFE6E8EC)),
//         ),
//         child: Row(
//           children: [
//             CheckoutIcon(PaymentGatewayService.nomodMethodIcon(method)),
//             SizedBox(width: context.w(12)),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     PaymentGatewayService.nomodMethodLabel(method),
//                     style: TextStyle(
//                       fontSize: context.fs(14),
//                       fontWeight: FontWeight.w600,
//                       color: const Color(0xFF0F172A),
//                     ),
//                   ),
//                   SizedBox(height: context.h(2)),
//                   Text(
//                     PaymentGatewayService.nomodMethodSubtitle(method),
//                     style: TextStyle(
//                       fontSize: context.fs(12),
//                       color: AppColors.subhead,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               Icons.chevron_right_rounded,
//               size: context.w(20),
//               color: AppColors.subhead,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
