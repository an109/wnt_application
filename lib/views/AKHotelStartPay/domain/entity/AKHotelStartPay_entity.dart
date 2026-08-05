import 'package:equatable/equatable.dart';

class AkHotelStartPayRequestEntity extends Equatable {
  final String transactionId;
  final double netAmount;
  final double paymentAmount;
  final String paymentReference;
  /// 'razorpay' | 'wallet' — this app's own gateways, matching the flight
  /// flow's StartPay gateway values (not Benzy's own gateway names like
  /// "nomod", which this app doesn't integrate).
  final String gateway;
  final String searchTracingKey;

  const AkHotelStartPayRequestEntity({
    required this.transactionId,
    required this.netAmount,
    required this.paymentAmount,
    required this.paymentReference,
    required this.gateway,
    required this.searchTracingKey,
  });

  @override
  List<Object?> get props => [transactionId, netAmount, paymentAmount, paymentReference, gateway, searchTracingKey];
}

class AkHotelStartPayEntity extends Equatable {
  final bool success;
  final String code;
  final String transactionId;
  /// e.g. "B0" = confirmed. See [isBooked].
  final String bookStatus;
  final String crsPnr;

  const AkHotelStartPayEntity({
    required this.success,
    required this.code,
    required this.transactionId,
    required this.bookStatus,
    required this.crsPnr,
  });

  bool get isBooked => bookStatus.toUpperCase() == 'B0';

  @override
  List<Object?> get props => [success, code, transactionId, bookStatus, crsPnr];
}
