import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final int? responseStatus;
  final int? errorCode;
  final String? errorMessage;
  final String? traceId;
  final String? pnr;
  final int? bookingId;
  final bool? isPriceChanged;
  final int? status;

  const BookingEntity({
    this.responseStatus,
    this.errorCode,
    this.errorMessage,
    this.traceId,
    this.pnr,
    this.bookingId,
    this.isPriceChanged,
    this.status,
  });

  bool get isSuccess => responseStatus == 1 && (errorCode == null || errorCode == 0);

  @override
  List<Object?> get props => [
    responseStatus, errorCode, errorMessage, traceId, pnr, bookingId, isPriceChanged, status,
  ];
}
