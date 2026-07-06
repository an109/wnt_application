import 'package:dio/dio.dart';

import '../../../core/constants/urls.dart';
import '../../../injection_container.dart' as di;
import '../../../core/network/dio_client.dart';

/// Thin client for the backend's CCAvenue hosted-checkout endpoints.
///
/// Uses the project's shared [DioClient] so the auth Bearer token and logging
/// interceptors are applied automatically (same as the rest of the app).
class CCAvenueService {
  Dio get _dio => di.sl<DioClient>().instance;

  /// Creates a payment session and returns the [CheckoutSession] whose
  /// [CheckoutSession.checkoutUrl] should be loaded in a WebView.
  Future<CheckoutSession> createCheckout({
    required double amount,
    required String successUrl,
    required String failureUrl,
    String? orderId,
    String currency = 'INR',
    String transactionType = 'flight',
    int? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final res = await _dio.post(
      Urls.ccavenueCreateCheckout,
      data: {
        // Let the backend generate the order_id unless one is explicitly given.
        if (orderId != null) 'order_id': orderId,
        'amount': amount,
        'currency': currency,
        'transaction_type': transactionType,
        if (userId != null) 'user_id': userId,
        'success_url': successUrl,
        'failure_url': failureUrl,
        'customer': {
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
          'email': email ?? '',
          'phone_number': phone ?? '',
        },
      },
    );

    final body = (res.data as Map).cast<String, dynamic>();
    if ((res.statusCode == 200 || res.statusCode == 201) &&
        body['success'] == true) {
      return CheckoutSession(
        checkoutUrl: body['checkout_url'] as String,
        orderId: body['order_id'] as String,
      );
    }
    throw CCAvenueException(
      body['error']?.toString() ?? 'Failed to create checkout',
    );
  }

  /// Calls the wallet `add-money` endpoint to create a pending wallet
  /// transaction record and get back a CCAvenue checkout URL + wallet reference.
  /// Use the returned [WalletTopUpSession] to open the WebView, then call
  /// [verifyWalletPayment] with [WalletTopUpSession.walletReference] on success.
  Future<WalletTopUpSession> initiateWalletTopUp({
    required double amount,
    String currency = 'INR',
  }) async {
    final res = await _dio.post(
      Urls.walletAddMoney,
      data: {
        'amount': amount,
        'currency': currency,
        'payment_method': 'ccavenue',
      },
    );
    final body = (res.data as Map).cast<String, dynamic>();
    if ((res.statusCode == 200 || res.statusCode == 201) &&
        body['success'] == true) {
      final checkoutUrl = body['checkout_url'] as String? ?? body['url'] as String? ?? '';
      final reference = body['reference'] as String? ?? body['order_id'] as String? ?? '';
      final orderId = body['order_id'] as String? ?? reference;
      if (checkoutUrl.isEmpty || reference.isEmpty) {
        throw CCAvenueException('Invalid add-money response from server');
      }
      return WalletTopUpSession(
        checkoutUrl: checkoutUrl,
        orderId: orderId,
        walletReference: reference,
      );
    }
    throw CCAvenueException(
      body['error']?.toString() ?? 'Failed to initiate wallet top-up',
    );
  }

  /// Notifies the wallet backend that a top-up payment completed so it can
  /// credit the wallet. Must be called after [getStatus] returns `"success"`
  /// for wallet transactions.
  Future<void> verifyWalletPayment(String reference) async {
    final res = await _dio.post(
      Urls.walletVerifyPayment,
      data: {'reference': reference},
    );
    final body = (res.data as Map).cast<String, dynamic>();
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw CCAvenueException(
        body['error']?.toString() ?? 'Wallet verify-payment failed',
      );
    }
  }

  /// Polls the backend for the authoritative final status.
  /// Returns one of: pending | success | failure | aborted.
  Future<String> getStatus(String orderId) async {
    final res = await _dio.get(Urls.ccavenueStatus(orderId));
    final body = (res.data as Map).cast<String, dynamic>();
    if (res.statusCode == 200 && body['success'] == true) {
      return body['status'] as String;
    }
    throw CCAvenueException(
      body['error']?.toString() ?? 'Status lookup failed',
    );
  }
}

class CheckoutSession {
  CheckoutSession({required this.checkoutUrl, required this.orderId});
  final String checkoutUrl;
  final String orderId;
}

class WalletTopUpSession {
  WalletTopUpSession({
    required this.checkoutUrl,
    required this.orderId,
    required this.walletReference,
  });
  final String checkoutUrl;
  final String orderId;
  final String walletReference;
}

class CCAvenueException implements Exception {
  CCAvenueException(this.message);
  final String message;
  @override
  String toString() => message;
}
