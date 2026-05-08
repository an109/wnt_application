import 'package:equatable/equatable.dart';

class FlightSearchRequestEntity extends Equatable {
  final String endUserIp;
  final int adultCount;
  final int childCount;
  final int infantCount;
  final int journeyType;
  final List<FlightSegmentEntity> segments;

  const FlightSearchRequestEntity({
    required this.endUserIp,
    required this.adultCount,
    required this.childCount,
    required this.infantCount,
    required this.journeyType,
    required this.segments,
  });

  @override
  List<Object?> get props => [
    endUserIp,
    adultCount,
    childCount,
    infantCount,
    journeyType,
    segments,
  ];
}

class FlightSegmentEntity extends Equatable {
  final String origin;
  final String destination;
  final int flightCabinClass;
  final String preferredDepartureTime;
  final String preferredArrivalTime;

  const FlightSegmentEntity({
    required this.origin,
    required this.destination,
    required this.flightCabinClass,
    required this.preferredDepartureTime,
    required this.preferredArrivalTime,
  });

  @override
  List<Object?> get props => [
    origin,
    destination,
    flightCabinClass,
    preferredDepartureTime,
    preferredArrivalTime,
  ];
}