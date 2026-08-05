
import 'package:equatable/equatable.dart';

class AkflightsEntity extends Equatable {
  final String index;
  final double netFare;
  final String provider;
  // The real IATA carrier code (API's "MAC" field). `provider` is an
  // internal fare-source label (e.g. "SB", "S6E") that can differ from the
  // actual operating/marketing airline, so this is what airline logos and
  // branding should key off instead.
  final String marketingAirlineCode;
  final String flightNo;
  final String departureTime;
  final String arrivalTime;
  final int stops;
  final String refundable;
  final String origin;
  final String destination;
  final String originName;
  final String destinationName;
  final String airlineName;
  final String duration;
  final String cabin;

  const AkflightsEntity({
    required this.index,
    required this.netFare,
    required this.provider,
    required this.marketingAirlineCode,
    required this.flightNo,
    required this.departureTime,
    required this.arrivalTime,
    required this.stops,
    required this.refundable,
    required this.origin,
    required this.destination,
    required this.originName,
    required this.destinationName,
    required this.airlineName,
    required this.duration,
    required this.cabin,
  });

  @override
  List<Object?> get props => [
    index,
    netFare,
    provider,
    marketingAirlineCode,
    flightNo,
    departureTime,
    arrivalTime,
    stops,
    refundable,
    origin,
    destination,
    originName,
    destinationName,
    airlineName,
    duration,
    cabin,
  ];
}

// A trip's Journey list is flat — each entry is a directly bookable flight
// option (fare class variant), not a group of connecting legs.
class TripEntity extends Equatable {
  final List<AkflightsEntity> journey;

  const TripEntity({required this.journey});

  @override
  List<Object?> get props => [journey];
}

class AkflightsSearchEntity extends Equatable {
  final bool success;
  final bool completed;
  final List<TripEntity> trips;

  const AkflightsSearchEntity({
    required this.success,
    required this.completed,
    required this.trips,
  });

  @override
  List<Object?> get props => [success, completed, trips];
}
