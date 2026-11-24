// import 'package:dio/dio.dart';
// import 'package:wander_nova/core/constants/urls.dart';
// import 'package:wander_nova/core/network/dio_client.dart';
// import 'package:wander_nova/injection_container.dart';
//
// class NomodCheckoutException implements Exception {
//   final String message;
//   final String? code;
//   const NomodCheckoutException(this.message, {this.code});
//   @override
//   String toString() => message;
// }
//
// class NomodCheckoutResult {
//   final String checkoutId;
//   final String checkoutUrl;
//   final String? orderId;
//
//   const NomodCheckoutResult({
//     required this.checkoutId,
//     required this.checkoutUrl,
//     this.orderId,
//   });
// }
//
// class NomodPaymentResult {
//   final String paymentId;
//   final String? orderId;
//   final bool success;
//   final String? error;
//
//   const NomodPaymentResult({
//     required this.paymentId,
//     this.orderId,
//     this.success = true,
//     this.error,
//   });
// }
//
// class NomodCheckoutService {
//   final Dio _dio = sl<DioClient>().instance;
//
//   Future<NomodCheckoutResult> createCheckout({
//     required double amount,
//     required String currency,
//     required String referenceId,
//     required String transactionType,
//     String? paymentMethod,
//     String? email,
//     String? phone,
//     String? customerName,
//     int? userId,
//   }) async {
//     try {
//       final response = await _dio.post(
//         Urls.nomodCreateCheckout,
//         data: {
//           'amount': amount.toStringAsFixed(2),
//           'currency': currency,
//           'reference_id': referenceId,
//           'transaction_type': transactionType,
//           if (paymentMethod != null) 'payment_method': paymentMethod,
//           if (email != null) 'email': email,
//           if (phone != null) 'phone': phone,
//           if (customerName != null) 'customer_name': customerName,
//           if (userId != null) 'user_id': userId,
//         },
//       );
//
//       final data = response.data as Map<String, dynamic>;
//       final checkoutId = data['checkout_id'] as String?;
//       final checkoutUrl = data['checkout_url'] as String?;
//
//       if (checkoutId == null || checkoutUrl == null) {
//         throw const NomodCheckoutException(
//             'Could not create payment session. Please try again.');
//       }
//
//       return NomodCheckoutResult(
//         checkoutId: checkoutId,
//         checkoutUrl: checkoutUrl,
//         orderId: data['order_id'] as String?,
//       );
//     } on DioException catch (e) {
//       final body = e.response?.data;
//       final msg = body is Map ? (body['error'] ?? body['message']) : null;
//       throw NomodCheckoutException(
//         msg?.toString() ?? 'Could not create payment session. Please try again.',
//       );
//     }
//   }
//
//   Future<NomodPaymentResult> verifyPayment({
//     required String checkoutId,
//     required String referenceId,
//   }) async {
//     try {
//       final response = await _dio.post(
//         Urls.nomodVerify,
//         data: {
//           'checkout_id': checkoutId,
//           'reference_id': referenceId,
//         },
//       );
//
//       final data = response.data as Map<String, dynamic>;
//       if (data['success'] == true) {
//         return NomodPaymentResult(
//           paymentId: (data['payment_id'] ?? checkoutId).toString(),
//           orderId: data['order_id'] as String?,
//         );
//       }
//       return NomodPaymentResult(
//         paymentId: checkoutId,
//         success: false,
//         error: (data['error'] ?? 'Payment verification failed').toString(),
//       );
//     } on DioException {
//       throw NomodCheckoutException(
//         'Could not verify payment. Please contact support.',
//       );
//     }
//   }
//
//   Future<Map<String, dynamic>> checkStatus(String checkoutId) async {
//     final response = await _dio.get(Urls.nomodCheckoutStatus(checkoutId));
//     return (response.data as Map).cast<String, dynamic>();
//   }
// }
