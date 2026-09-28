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

/// A UPI app installed on the device (GPay, PhonePe, Paytm, …).
class UpiApp {
  final String name;
  final String package;

  const UpiApp({required this.name, required this.package});

  String get _id => '${name.toLowerCase()} ${package.toLowerCase()}';

  bool get isGooglePay =>
      _id.contains('google') || _id.contains('gpay') || _id.contains('tez') ||
      _id.contains('nbu.paisa');
  bool get isPhonePe => _id.contains('phonepe');
  bool get isPaytm => _id.contains('paytm');
}

/// Thin bridge to the native Razorpay Custom Checkout SDKs — Android
/// (`com.razorpay:customui`, wired up in `MainActivity.kt`) and iOS
/// (`razorpay-customui-pod`, wired up in `AppDelegate.swift`) — over one
/// shared method channel with the same contract on both platforms.
class RazorpayCustomCheckoutService {
  static const _channel = MethodChannel('wander_nova/razorpay_custom');

  bool get isSupported => Platform.isAndroid || Platform.isIOS;

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

  /// UPI apps installed on this device that can complete a UPI intent
  /// payment, as `{name, package}` — pass `package` as the payload's
  /// `upi_app_package_name`. Empty when none are installed.
  Future<List<UpiApp>> getUpiApps() async {
    _assertSupported();
    try {
      final raw = await _channel.invokeListMethod<dynamic>('getUpiApps');
      return (raw ?? const [])
          .whereType<Map>()
          .map((m) => UpiApp(
                name: (m['name'] ?? '').toString(),
                package: (m['package'] ?? '').toString(),
              ))
          .where((a) => a.package.isNotEmpty)
          .toList();
    } on PlatformException catch (e) {
      throw RazorpayCustomCheckoutException(
        e.message ?? 'Could not load UPI apps',
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
        'This payment method is not supported on this device.',
      );
    }
  }
}
