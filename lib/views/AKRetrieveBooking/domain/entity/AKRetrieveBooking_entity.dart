import 'package:equatable/equatable.dart';

class AkRetrieveBookingRequestEntity extends Equatable {
  final String sessionId;

  const AkRetrieveBookingRequestEntity({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class AkTicketInfoEntity extends Equatable {
  final String paxId;
  final String ticketNo;

  const AkTicketInfoEntity({required this.paxId, required this.ticketNo});

  @override
  List<Object?> get props => [paxId, ticketNo];
}

class AkRetrieveSegmentEntity extends Equatable {
  final String crsPnr;
  final String flightNo;
  final List<AkTicketInfoEntity> ticketInfo;

  const AkRetrieveSegmentEntity({
    required this.crsPnr,
    required this.flightNo,
    required this.ticketInfo,
  });

  @override
  List<Object?> get props => [crsPnr, flightNo, ticketInfo];
}

class AkRetrieveJourneyEntity extends Equatable {
  final List<AkRetrieveSegmentEntity> segments;

  const AkRetrieveJourneyEntity({required this.segments});

  @override
  List<Object?> get props => [segments];
}

class AkRetrieveTripEntity extends Equatable {
  final List<AkRetrieveJourneyEntity> journey;

  const AkRetrieveTripEntity({required this.journey});

  @override
  List<Object?> get props => [journey];
}

class AkRetrieveBookingEntity extends Equatable {
  final bool success;
  // There is no top-level PNR field on this response — use this list.
  final List<String> pnrs;
  final String status;
  final List<AkRetrieveTripEntity> trips;

  const AkRetrieveBookingEntity({
    required this.success,
    required this.pnrs,
    required this.status,
    required this.trips,
  });

  /// All ticket numbers across every segment, flattened for a simple
  /// confirmation-screen summary.
  List<AkTicketInfoEntity> get allTicketInfo => trips
      .expand((t) => t.journey)
      .expand((j) => j.segments)
      .expand((s) => s.ticketInfo)
      .toList();

  @override
  List<Object?> get props => [success, pnrs, status, trips];
}
