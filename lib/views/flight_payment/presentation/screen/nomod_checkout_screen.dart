// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:wander_nova/UI_helper/responsive_layout.dart';
// import 'package:wander_nova/core/resources/app_colours.dart';
//
// import '../../data/nomod_checkout_service.dart';
//
// /// WebView-based Nomod checkout screen used for all UAE payments.
// ///
// /// Opens the hosted Nomod checkout URL and monitors navigation for
// /// success/failure redirects. Pops with a [NomodPaymentResult] on
// /// success, or null on cancellation/failure.
// class NomodCheckoutScreen extends StatefulWidget {
//   final String checkoutUrl;
//   final String checkoutId;
//   final String referenceId;
//
//   const NomodCheckoutScreen({
//     super.key,
//     required this.checkoutUrl,
//     required this.checkoutId,
//     required this.referenceId,
//   });
//
//   @override
//   State<NomodCheckoutScreen> createState() => _NomodCheckoutScreenState();
// }
//
// class _NomodCheckoutScreenState extends State<NomodCheckoutScreen> {
//   late final WebViewController _controller;
//   bool _loading = true;
//   bool _processing = false;
//   final _nomodService = NomodCheckoutService();
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(NavigationDelegate(
//         onPageStarted: (_) {
//           if (mounted) setState(() => _loading = true);
//         },
//         onPageFinished: (_) {
//           if (mounted) setState(() => _loading = false);
//         },
//         onNavigationRequest: (request) {
//           final url = request.url.toLowerCase();
//           if (url.contains('/payment/success') || url.contains('status=success') || url.contains('payment_status=paid')) {
//             _handleSuccess();
//             return NavigationDecision.prevent;
//           }
//           if (url.contains('/payment/failed') || url.contains('status=failed') || url.contains('payment_status=failed')) {
//             _handleFailure('Payment was not completed. Please try again.');
//             return NavigationDecision.prevent;
//           }
//           if (url.contains('/payment/cancel') || url.contains('status=cancelled')) {
//             _handleFailure(null);
//             return NavigationDecision.prevent;
//           }
//           return NavigationDecision.navigate;
//         },
//       ))
//       ..loadRequest(Uri.parse(widget.checkoutUrl));
//   }
//
//   Future<void> _handleSuccess() async {
//     if (_processing) return;
//     setState(() => _processing = true);
//
//     try {
//       final result = await _nomodService.verifyPayment(
//         checkoutId: widget.checkoutId,
//         referenceId: widget.referenceId,
//       );
//       if (!mounted) return;
//       if (result.success) {
//         Navigator.of(context).pop(result);
//       } else {
//         Navigator.of(context).pop(null);
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(result.error ?? 'Payment verification failed'),
//           backgroundColor: Colors.red,
//         ));
//       }
//     } on NomodCheckoutException catch (e) {
//       if (!mounted) return;
//       Navigator.of(context).pop(null);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(e.message),
//         backgroundColor: Colors.red,
//       ));
//     }
//   }
//
//   void _handleFailure(String? message) {
//     if (!mounted) return;
//     Navigator.of(context).pop(null);
//     if (message != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//       ));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.black),
//           onPressed: () => Navigator.of(context).pop(null),
//         ),
//         title: Text(
//           'Complete Payment',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: context.fs(18),
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_loading || _processing)
//             Container(
//               color: Colors.white.withValues(alpha: 0.7),
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const CircularProgressIndicator(color: AppColors.AppBlue),
//                     SizedBox(height: context.h(16)),
//                     Text(
//                       _processing ? 'Verifying payment...' : 'Loading checkout...',
//                       style: TextStyle(
//                         fontSize: context.fs(14),
//                         color: AppColors.subhead,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
