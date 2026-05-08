import '../../domain/entities/flight_search_request_entity.dart';

class FlightSearchRequestModel extends FlightSearchRequestEntity {
  const FlightSearchRequestModel({
    required String endUserIp,
    required int adultCount,
    required int childCount,
    required int infantCount,
    required int journeyType,
    required List<FlightSegmentModel> segments,
  }) : super(
    endUserIp: endUserIp,
    adultCount: adultCount,
    childCount: childCount,
    infantCount: infantCount,
    journeyType: journeyType,
    segments: segments,
  );

  Map<String, dynamic> toJson() {
    return {
      'EndUserIp': endUserIp,
      'AdultCount': adultCount,
      'ChildCount': childCount,
      'InfantCount': infantCount,
      'JourneyType': journeyType,
      'Segments': (segments as List<FlightSegmentModel>)
          .map((segment) => segment.toJson())
          .toList(),
    };
  }

  factory FlightSearchRequestModel.fromEntity(FlightSearchRequestEntity entity) {
    return FlightSearchRequestModel(
      endUserIp: entity.endUserIp,
      adultCount: entity.adultCount,
      childCount: entity.childCount,
      infantCount: entity.infantCount,
      journeyType: entity.journeyType,
      segments: entity.segments
          .map((segment) => FlightSegmentModel.fromEntity(segment))
          .toList(),
    );
  }
}

class FlightSegmentModel extends FlightSegmentEntity {
  const FlightSegmentModel({
    required String origin,
    required String destination,
    required int flightCabinClass,
    required String preferredDepartureTime,
    required String preferredArrivalTime,
  }) : super(
    origin: origin,
    destination: destination,
    flightCabinClass: flightCabinClass,
    preferredDepartureTime: preferredDepartureTime,
    preferredArrivalTime: preferredArrivalTime,
  );

  Map<String, dynamic> toJson() {
    return {
      'Origin': origin,
      'Destination': destination,
      'FlightCabinClass': flightCabinClass,
      'PreferredDepartureTime': preferredDepartureTime,
      'PreferredArrivalTime': preferredArrivalTime,
    };
  }

  factory FlightSegmentModel.fromEntity(FlightSegmentEntity entity) {
    return FlightSegmentModel(
      origin: entity.origin,
      destination: entity.destination,
      flightCabinClass: entity.flightCabinClass,
      preferredDepartureTime: entity.preferredDepartureTime,
      preferredArrivalTime: entity.preferredArrivalTime,
    );
  }
}