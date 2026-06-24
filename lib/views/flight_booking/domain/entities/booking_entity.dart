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

  // TBO's flat Book response uses "Status":1 (not "ResponseStatus"):
  //   Flat success  → Status=1, ResponseStatus=null
  //   Flat failure  → Status=0, ResponseStatus=null, Errors=[...]
  //   Wrapped error → ResponseStatus=0, Error={...}
  bool get isSuccess =>
      (responseStatus == 1 || status == 1) &&
      (errorCode == null || errorCode == 0) &&
      pnr != null &&
      pnr!.isNotEmpty;

  @override
  List<Object?> get props => [
    responseStatus, errorCode, errorMessage, traceId, pnr, bookingId, isPriceChanged, status,
  ];
}
