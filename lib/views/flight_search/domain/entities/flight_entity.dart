import 'package:equatable/equatable.dart';

class FlightEntity extends Equatable {
  final String? resultIndex;
  final String? airlineCode;
  final String? airlineName;
  final String? flightNumber;
  final String? origin;
  final String? destination;
  final String? departureTime;
  final String? arrivalTime;
  final String? duration;
  final String? cabinClass;
  final double? baseFare;
  final double? tax;
  final double? totalFare;
  final String? currency;
  final int? seatsAvailable;
  final String? traceId;

  const FlightEntity({
    this.resultIndex,
    this.airlineCode,
    this.airlineName,
    this.flightNumber,
    this.origin,
    this.destination,
    this.departureTime,
    this.arrivalTime,
    this.duration,
    this.cabinClass,
    this.baseFare,
    this.tax,
    this.totalFare,
    this.currency,
    this.seatsAvailable,
    this.traceId,
  });

  @override
  List<Object?> get props => [
    resultIndex,
    airlineCode,
    airlineName,
    flightNumber,
    origin,
    destination,
    departureTime,
    arrivalTime,
    duration,
    cabinClass,
    baseFare,
    tax,
    totalFare,
    currency,
    seatsAvailable,
    traceId,
  ];
}