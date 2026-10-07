import 'package:dio/dio.dart';

import '../../../../../core/constants/urls.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../injection_container.dart';

/// A row of `GET /api/refunds/my/` for one flight booking.
class FlightRefund {
  /// pending | processing | completed | rejected
  final String status;

  /// account | wallet
  final String refundType;
  final double refundAmount;
  final double providerPenalty;
  final double platformFee;
  final String currency;
  final String reference;
  final DateTime? created;

  const FlightRefund({
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

  factory FlightRefund.fromJson(Map<String, dynamic> j) => FlightRefund(
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

/// Refund lookup for the cancelled-trip details screen.
class FlightRefundService {
  FlightRefundService({Dio? dio}) : _dio = dio ?? sl<DioClient>().instance;

  final Dio _dio;

  /// The latest refund request for [bookingId] (matched by booking id, else
  /// by PNR), or null if the user hasn't got one.
  Future<FlightRefund?> forBooking({required int bookingId, required String pnr}) async {
    final res = await _dio.get(Urls.myRefunds, queryParameters: {'page_size': 100});
    final data = res.data is Map ? res.data as Map : const {};
    for (final row in (data['refund_requests'] as List? ?? const [])) {
      if (row is! Map) continue;
      final r = Map<String, dynamic>.from(row);
      if (r['booking_type'] != 'flight') continue;
      final fb = r['flight_booking'];
      final id = fb is Map ? fb['id'] : fb;
      final samePnr = pnr.isNotEmpty && (r['pnr'] ?? '').toString() == pnr;
      if ('$id' == '$bookingId' || samePnr) return FlightRefund.fromJson(r);
    }
    return null;
  }

  /// Admin-configured refund processing time in days, if set.
  Future<int?> processingDays() async {
    final res = await _dio.get(Urls.cancellationSettings);
    final settings = res.data is Map ? (res.data as Map)['settings'] : null;
    if (settings is! Map) return null;
    return int.tryParse('${settings['refund_processing_days'] ?? ''}');
  }
}
