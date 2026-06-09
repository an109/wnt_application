// import 'package:equatable/equatable.dart';
//
// class FlightEntity extends Equatable {
//   final String? resultIndex;
//   final String? airlineCode;
//   final String? airlineName;
//   final String? flightNumber;
//   final String? origin;
//   final String? destination;
//   final String? departureTime;
//   final String? arrivalTime;
//   final String? duration;
//   final String? cabinClass;
//   final double? baseFare;
//   final double? tax;
//   final double? totalFare;
//   final String? currency;
//   final int? seatsAvailable;
//   final String? traceId;
//
//   const FlightEntity({
//     this.resultIndex,
//     this.airlineCode,
//     this.airlineName,
//     this.flightNumber,
//     this.origin,
//     this.destination,
//     this.departureTime,
//     this.arrivalTime,
//     this.duration,
//     this.cabinClass,
//     this.baseFare,
//     this.tax,
//     this.totalFare,
//     this.currency,
//     this.seatsAvailable,
//     this.traceId,
//   });
//
//   @override
//   List<Object?> get props => [
//     resultIndex,
//     airlineCode,
//     airlineName,
//     flightNumber,
//     origin,
//     destination,
//     departureTime,
//     arrivalTime,
//     duration,
//     cabinClass,
//     baseFare,
//     tax,
//     totalFare,
//     currency,
//     seatsAvailable,
//     traceId,
//   ];
// }

import 'package:equatable/equatable.dart';

class FlightEntity extends Equatable {
  final String? resultIndex;
  final String? airlineCode;
  final String? airlineName;
  final String? flightNumber;
  final String? origin;
  final String? originName;
  final String? destination;
  final String? destinationName;
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

  // Number of stops on the outbound journey (0 = non-stop), as derived
  // from the API's segment legs.
  final int? stops;

  // Round trip details
  final bool isRoundTrip;
  final String? returnDepartureTime;
  final String? returnArrivalTime;
  final String? returnDuration;
  final String? returnOrigin;
  final String? returnOriginName;
  final String? returnDestination;
  final String? returnDestinationName;
  final int? returnStops;

  const FlightEntity({
    this.resultIndex,
    this.airlineCode,
    this.airlineName,
    this.flightNumber,
    this.origin,
    this.originName,
    this.destination,
    this.destinationName,
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
    this.stops,
    this.isRoundTrip = false,
    this.returnDepartureTime,
    this.returnArrivalTime,
    this.returnDuration,
    this.returnOrigin,
    this.returnOriginName,
    this.returnDestination,
    this.returnDestinationName,
    this.returnStops,
  });

  @override
  List<Object?> get props => [
    resultIndex, airlineCode, airlineName, flightNumber, origin, originName,
    destination, destinationName, departureTime, arrivalTime, duration, cabinClass,
    baseFare, tax, totalFare, currency, seatsAvailable, traceId, stops, isRoundTrip,
    returnDepartureTime, returnArrivalTime, returnDuration, returnOrigin,
    returnOriginName, returnDestination, returnDestinationName, returnStops,
  ];
}