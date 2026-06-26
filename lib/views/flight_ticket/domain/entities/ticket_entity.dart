import 'package:equatable/equatable.dart';

class TicketPassengerEntity extends Equatable {
  final int? paxId;
  final String? ticketId;
  final String? ticketNumber;
  final String? status;
  final String? firstName;
  final String? lastName;

  const TicketPassengerEntity({
    this.paxId,
    this.ticketId,
    this.ticketNumber,
    this.status,
    this.firstName,
    this.lastName,
  });

  @override
  List<Object?> get props => [paxId, ticketId, ticketNumber, status, firstName, lastName];
}

class TicketEntity extends Equatable {
  final int? responseStatus;
  final int? errorCode;
  final String? errorMessage;
  final String? traceId;
  final String? pnr;
  final int? bookingId;
  final List<TicketPassengerEntity>? passengers;

  const TicketEntity({
    this.responseStatus,
    this.errorCode,
    this.errorMessage,
    this.traceId,
    this.pnr,
    this.bookingId,
    this.passengers,
  });

  // TBO Ticket status codes:
  //   1 = In Progress (awaiting airline/GDS confirmation)
  //   2 = Confirmed
  //   5 = Ticketed (direct by airline)
  //   8 = Ticketed with price change (ticket issued, fare changed vs. quoted)
  bool get isSuccess =>
      (responseStatus == 2 || responseStatus == 5 || responseStatus == 8) &&
      (errorCode == null || errorCode == 0);

  bool get isPending =>
      responseStatus == 1 && (errorCode == null || errorCode == 0);

  @override
  List<Object?> get props => [
    responseStatus, errorCode, errorMessage, traceId, pnr, bookingId, passengers,
  ];
}
