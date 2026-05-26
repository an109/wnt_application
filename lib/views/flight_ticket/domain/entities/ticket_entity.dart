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

  bool get isSuccess => responseStatus == 1 && (errorCode == null || errorCode == 0);

  bool get isPending => passengers != null &&
      passengers!.any((p) => p.status?.toLowerCase() == 'pending');

  @override
  List<Object?> get props => [
    responseStatus, errorCode, errorMessage, traceId, pnr, bookingId, passengers,
  ];
}
