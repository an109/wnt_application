import 'package:equatable/equatable.dart';

class AkStartPayRequestEntity extends Equatable {
  final String sessionId;
  final String gateway;

  const AkStartPayRequestEntity({
    required this.sessionId,
    required this.gateway,
  });

  @override
  List<Object?> get props => [sessionId, gateway];
}

class AkStartPayEntity extends Equatable {
  final bool success;
  final String? pnr;
  final String? status;
  final String? bookStatus;
  // A response that hiccuped (timeout / "already initiated") but was
  // reconciled server-side into a real booking — treat exactly like success.
  final bool recovered;
  // True on HTTP 202 {"error":"booking_in_progress"} — not a failure, the
  // caller should wait retryAfterSeconds and call StartPay again.
  final bool bookingInProgress;
  final int? retryAfterSeconds;

  const AkStartPayEntity({
    required this.success,
    this.pnr,
    this.status,
    this.bookStatus,
    required this.recovered,
    required this.bookingInProgress,
    this.retryAfterSeconds,
  });

  /// True when the booking is confirmed either normally or via recovery —
  /// the two outcomes the doc says to treat identically.
  bool get isBooked => success || recovered;

  @override
  List<Object?> get props => [
    success, pnr, status, bookStatus, recovered, bookingInProgress, retryAfterSeconds,
  ];
}
