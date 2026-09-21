import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Thrown for any failure surfaced by [RazorpayCustomCheckoutService] —
/// unsupported platform, a native SDK error, or a failed/cancelled payment.
class RazorpayCustomCheckoutException implements Exception {
  final String message;
  final String? code;

  const RazorpayCustomCheckoutException(this.message, {this.code});

  @override
  String toString() => message;
}

/// A completed Razorpay charge, ready for the app's existing
/// `payments/razorpay/verify/` signature check.
class RazorpayCustomPaymentResult {
  final String paymentId;
  final String? orderId;
  final String? signature;

  const RazorpayCustomPaymentResult({
    required this.paymentId,
    this.orderId,
    this.signature,
  });
}

/// Thin bridge to the native Razorpay Android Custom Checkout SDK
/// (`com.razorpay:customui`), wired up natively in `MainActivity.kt`.
///
/// Razorpay does not publish an iOS Custom Checkout SDK, so every call here
/// throws on non-Android platforms — callers should keep payment methods
/// unrelated to Razorpay (e.g. the WanderNova wallet) available on iOS
/// instead of routing to a custom-checkout screen.
class RazorpayCustomCheckoutService {
  static const _channel = MethodChannel('wander_nova/razorpay_custom');

  bool get isSupported => Platform.isAndroid;

  /// Payment methods enabled on this Razorpay account (doc step 1.4) — used
  /// so the netbanking/wallet pickers only ever show real, enabled options
  /// instead of a static list.
  Future<Map<String, dynamic>> getPaymentMethods({required String keyId}) async {
    _assertSupported();
    try {
      final raw = await _channel.invokeMethod<String>('getPaymentMethods', {'keyId': keyId});
      if (raw == null || raw.isEmpty) return {};
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } on PlatformException catch (e) {
      throw RazorpayCustomCheckoutException(
        e.message ?? 'Could not load payment methods',
        code: e.code,
      );
    }
  }

  /// Submits the method-specific payload built by the caller (doc step 1.6)
  /// and resolves once the native SDK reports success — cancellation and
  /// hard failures both surface as [RazorpayCustomCheckoutException].
  Future<RazorpayCustomPaymentResult> submitPayment({
    required String keyId,
    required Map<String, dynamic> data,
  }) async {
    _assertSupported();
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('submitPayment', {
        'keyId': keyId,
        'data': jsonEncode(data),
      });
      final paymentId = result?['paymentId'] as String?;
      if (paymentId == null || paymentId.isEmpty) {
        throw const RazorpayCustomCheckoutException('Payment did not complete');
      }
      return RazorpayCustomPaymentResult(
        paymentId: paymentId,
        orderId: result?['orderId'] as String?,
        signature: result?['signature'] as String?,
      );
    } on PlatformException catch (e) {
      throw RazorpayCustomCheckoutException(
        e.message ?? 'Payment failed. Please try again.',
        code: e.code,
      );
    }
  }

  void _assertSupported() {
    if (!isSupported) {
      throw const RazorpayCustomCheckoutException(
        'This payment method is available on Android for now.',
      );
    }
  }
}
