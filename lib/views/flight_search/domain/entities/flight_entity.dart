import 'package:equatable/equatable.dart';
import 'fare_entity.dart';

class FlightEntity extends Equatable {
  final String flightNumber;
  final String airline;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int duration;
  final FareEntity fare;
  final String cabinClass;

  const FlightEntity({
    required this.flightNumber,
    required this.airline,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.fare,
    required this.cabinClass,
  });

  @override
  List<Object?> get props => [
    flightNumber,
    airline,
    origin,
    destination,
    departureTime,
    arrivalTime,
    duration,
    fare,
    cabinClass,
  ];
}