import 'package:dio/dio.dart';

import '../../../core/constants/urls.dart';
import '../../../core/network/dio_client.dart';
import '../../../injection_container.dart';

class BookingRefund {
  final String status;
  final String refundType;
  final double refundAmount;
  final double providerPenalty;
  final double platformFee;
  final String currency;
  final String reference;
  final DateTime? created;

  const BookingRefund({
    required this.status,
    required this.refundType,
    required this.refundAmount,
    required this.providerPenalty,
    required this.platformFee,
    required this.currency,
    required this.reference,
    required this.created,
  });

  static double _num(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

  factory BookingRefund.fromJson(Map<String, dynamic> j) => BookingRefund(
    status: (j['status'] ?? '').toString(),
    refundType: (j['refund_type'] ?? '').toString(),
    refundAmount: _num(j['refund_amount']),
    providerPenalty: _num(j['provider_penalty']),
    platformFee: _num(j['platform_fee']),
    currency: (j['currency'] ?? 'INR').toString(),
    reference: (j['reference'] ?? '').toString(),
    created: DateTime.tryParse((j['created'] ?? '').toString())?.toLocal(),
  );
}

class BookingRefundService {
  BookingRefundService({Dio? dio}) : _dio = dio ?? sl<DioClient>().instance;

  final Dio _dio;

  Future<BookingRefund?> forBooking({
    required String bookingType,
    required int bookingId,
    String? pnr,
  }) async {
    final res = await _dio.get(Urls.myRefunds, queryParameters: {'page_size': 100});
    final data = res.data is Map ? res.data as Map : const {};
    for (final row in (data['refund_requests'] as List? ?? const [])) {
      if (row is! Map) continue;
      final r = Map<String, dynamic>.from(row);
      if (r['booking_type'] != bookingType) continue;

      final bookingField = r['${bookingType}_booking'];
      final id = bookingField is Map ? bookingField['id'] : bookingField;
      final samePnr = pnr != null && pnr.isNotEmpty && (r['pnr'] ?? '').toString() == pnr;
      if ('$id' == '$bookingId' || samePnr) return BookingRefund.fromJson(r);
    }
    return null;
  }

  Future<int?> processingDays() async {
    final res = await _dio.get(Urls.cancellationSettings);
    final settings = res.data is Map ? (res.data as Map)['settings'] : null;
    if (settings is! Map) return null;
    return int.tryParse('${settings['refund_processing_days'] ?? ''}');
  }
}
