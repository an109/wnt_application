import '../../domain/entity/AKStartPay_entity.dart';

class AkStartPayRequestModel extends AkStartPayRequestEntity {
  const AkStartPayRequestModel({
    required super.sessionId,
    required super.gateway,
  });

  factory AkStartPayRequestModel.fromEntity(AkStartPayRequestEntity entity) {
    return AkStartPayRequestModel(sessionId: entity.sessionId, gateway: entity.gateway);
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'gateway': gateway,
    };
  }
}

class AkStartPayModel extends AkStartPayEntity {
  const AkStartPayModel({
    required super.success,
    super.pnr,
    super.status,
    super.bookStatus,
    required super.recovered,
    required super.bookingInProgress,
    super.retryAfterSeconds,
  });

  factory AkStartPayModel.fromJson(Map<String, dynamic> json) {
    return AkStartPayModel(
      success: json['success'] ?? false,
      pnr: json['pnr']?.toString(),
      status: json['status']?.toString(),
      bookStatus: json['book_status']?.toString(),
      recovered: json['recovered'] == true,
      bookingInProgress: false,
      retryAfterSeconds: null,
    );
  }

  /// Built from an HTTP 202 `{"error":"booking_in_progress","retry_after":n}`
  /// response — not a failure, the caller should retry after the delay.
  factory AkStartPayModel.bookingInProgress(Map<String, dynamic> json) {
    final retryAfter = json['retry_after'];
    return AkStartPayModel(
      success: false,
      recovered: false,
      bookingInProgress: true,
      retryAfterSeconds: retryAfter is num ? retryAfter.toInt() : null,
    );
  }
}
