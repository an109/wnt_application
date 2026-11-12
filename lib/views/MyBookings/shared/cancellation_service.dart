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

  /// Cancel an Akbar flight. The server re-checks the ticket with the airline
  /// system first and blocks non-refundable fares. Only `success: true` counts.
  Future<void> cancelAkbarFlight(int flightBookingId) async {
    try {
      final res = await _dio.post(
        Urls.akFlightCancel,
        data: {
          'booking_id': flightBookingId,
          'remarks': 'Cancellation requested by customer',
        },
      );
      final data = res.data is Map ? res.data as Map : const {};
      if (data['success'] != true) {
        throw Exception(data['error']?.toString() ?? 'Flight cancellation failed');
      }
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = body is Map ? body['error']?.toString() : null;
      throw Exception(msg ?? 'Flight cancellation failed');
    }
  }

  /// Cancel an Akbar hotel booking. The server re-reads the booking from the
  /// supplier first and only answers success once the cancellation is
  /// confirmed, so anything other than success: true is a failure.
  Future<void> cancelAkbarHotel(String transactionId) async {
    final res = await _dio.post(
      Urls.akHotelCancel,
      data: {
        'TransactionID': transactionId,
        'Remarks': 'Cancellation requested by customer',
      },
    );
    final data = res.data is Map ? res.data as Map : const {};
    if (data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Hotel cancellation failed');
    }
  }

  /// True when the supplier already shows this TBO booking as cancelled.
  Future<bool> tboHotelIsCancelled(String bookingReferenceId) async {
    final res = await _dio.post(
      Urls.hotelBookingDetail,
      data: {'BookingReferenceId': bookingReferenceId, 'PaymentMode': 'Limit'},
    );
    final d = res.data is Map ? res.data as Map : const {};
    final list = (d['HotelResult'] ?? d['HotelResults']) as List? ?? const [];
    if (list.isEmpty || list.first is! Map) return false;
    return (list.first as Map)['BookingStatus'] == 'Cancelled';
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
