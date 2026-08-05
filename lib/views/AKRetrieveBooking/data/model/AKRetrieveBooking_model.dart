import '../../domain/entity/AKRetrieveBooking_entity.dart';

class AkRetrieveBookingRequestModel extends AkRetrieveBookingRequestEntity {
  const AkRetrieveBookingRequestModel({required super.sessionId});

  factory AkRetrieveBookingRequestModel.fromEntity(AkRetrieveBookingRequestEntity entity) {
    return AkRetrieveBookingRequestModel(sessionId: entity.sessionId);
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
    };
  }
}

class AkTicketInfoModel extends AkTicketInfoEntity {
  const AkTicketInfoModel({required super.paxId, required super.ticketNo});

  factory AkTicketInfoModel.fromJson(Map<String, dynamic> json) {
    return AkTicketInfoModel(
      paxId: json['PaxID']?.toString() ?? '',
      ticketNo: json['TicketNo']?.toString() ?? '',
    );
  }
}

class AkRetrieveSegmentModel extends AkRetrieveSegmentEntity {
  const AkRetrieveSegmentModel({
    required super.crsPnr,
    required super.flightNo,
    required super.ticketInfo,
  });

  factory AkRetrieveSegmentModel.fromJson(Map<String, dynamic> json) {
    final flight = json['Flight'] as Map<String, dynamic>? ?? {};
    final ticketInfoList = flight['TicketInfo'] as List? ?? [];
    return AkRetrieveSegmentModel(
      crsPnr: flight['CRSPNR']?.toString() ?? '',
      flightNo: flight['FlightNo']?.toString() ?? '',
      ticketInfo: ticketInfoList
          .whereType<Map<String, dynamic>>()
          .map((e) => AkTicketInfoModel.fromJson(e))
          .toList(),
    );
  }
}

class AkRetrieveJourneyModel extends AkRetrieveJourneyEntity {
  const AkRetrieveJourneyModel({required super.segments});

  factory AkRetrieveJourneyModel.fromJson(Map<String, dynamic> json) {
    final segmentsList = json['Segments'] as List? ?? [];
    return AkRetrieveJourneyModel(
      segments: segmentsList
          .whereType<Map<String, dynamic>>()
          .map((e) => AkRetrieveSegmentModel.fromJson(e))
          .toList(),
    );
  }
}

class AkRetrieveTripModel extends AkRetrieveTripEntity {
  const AkRetrieveTripModel({required super.journey});

  factory AkRetrieveTripModel.fromJson(Map<String, dynamic> json) {
    final journeyList = json['Journey'] as List? ?? [];
    return AkRetrieveTripModel(
      journey: journeyList
          .whereType<Map<String, dynamic>>()
          .map((e) => AkRetrieveJourneyModel.fromJson(e))
          .toList(),
    );
  }
}

class AkRetrieveBookingModel extends AkRetrieveBookingEntity {
  const AkRetrieveBookingModel({
    required super.success,
    required super.pnrs,
    required super.status,
    required super.trips,
  });

  factory AkRetrieveBookingModel.fromJson(Map<String, dynamic> json) {
    final pnrsList = json['pnrs'] as List? ?? [];
    final tripsList = json['Trips'] as List? ?? [];
    return AkRetrieveBookingModel(
      success: json['success'] ?? false,
      pnrs: pnrsList.map((e) => e.toString()).toList(),
      status: json['Status']?.toString() ?? '',
      trips: tripsList
          .whereType<Map<String, dynamic>>()
          .map((e) => AkRetrieveTripModel.fromJson(e))
          .toList(),
    );
  }
}
