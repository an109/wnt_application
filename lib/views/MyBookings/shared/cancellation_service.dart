import 'package:dio/dio.dart';

import '../../../core/constants/urls.dart';
import '../../../core/network/dio_client.dart';
import '../../../injection_container.dart';

class CancellationService {
  CancellationService({Dio? dio}) : _dio = dio ?? sl<DioClient>().instance;

  final Dio _dio;

  /// Cancel a TBO hotel booking.
  Future<Map<String, dynamic>> cancelHotel(String confirmationNumber) async {
    final res = await _dio.post(
      Urls.hotelCancel,
      data: {'ConfirmationNumber': confirmationNumber},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Cancel a Mozio transport reservation.
  Future<void> cancelTransport(String reservationId) async {
    await _dio.delete('${Urls.transportReservations}$reservationId/');
  }

  /// Submit an auto-refund request (mirrors frontend processAutoRefund).
  Future<Map<String, dynamic>> autoRefund({
    required String bookingType,
    required int bookingId,
    required String refundMethod,
    required double originalAmount,
    double providerPenalty = 0,
    String? checkoutId,
    String? ccavenueOrderId,
    String? paidVia,
    String? razorpayOrderId,
  }) async {
    final effectiveCheckoutId = paidVia == 'razorpay'
        ? (razorpayOrderId ?? checkoutId ?? '')
        : (checkoutId ?? '');

    final res = await _dio.post(
      Urls.autoRefund,
      data: {
        'booking_type': bookingType,
        'booking_id': bookingId,
        'refund_method': refundMethod,
        'original_amount': originalAmount,
        'provider_penalty': providerPenalty,
        if (effectiveCheckoutId.isNotEmpty) 'checkout_id': effectiveCheckoutId,
        if (ccavenueOrderId != null && ccavenueOrderId.isNotEmpty)
          'ccavenue_order_id': ccavenueOrderId,
        if (paidVia != null && paidVia.isNotEmpty) 'paid_via': paidVia,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
