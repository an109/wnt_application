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
  final Map<String, dynamic>? rawResponse;

  const BookingEntity({
    this.responseStatus,
    this.errorCode,
    this.errorMessage,
    this.traceId,
    this.pnr,
    this.bookingId,
    this.isPriceChanged,
    this.status,
    this.rawResponse,
  });

  // TBO Book status codes:
  //   1 = In Progress (hold, then Ticket separately)
  //   2 = Confirmed
  //   5 = Ticketed (direct ticket — Air India and some GDS airlines)
  // All three indicate a successful booking with a valid PNR.
  bool get isSuccess =>
      (responseStatus == 1 || status == 1 ||
       responseStatus == 2 || status == 2 ||
       responseStatus == 5 || status == 5) &&
      (errorCode == null || errorCode == 0) &&
      pnr != null &&
      pnr!.isNotEmpty;

  @override
  List<Object?> get props => [
    responseStatus, errorCode, errorMessage, traceId, pnr, bookingId, isPriceChanged, status, rawResponse,
  ];
}
