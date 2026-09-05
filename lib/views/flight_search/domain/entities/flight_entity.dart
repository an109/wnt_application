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

/// One sibling fare-class variant (Saver/Flexi/SME/...) of the same physical
/// flight, as GetExpSearch returns them — same airline+flightNo+departureTime,
/// different Index/NetFare. The search-results list only shows the cheapest
/// one per flight (see `_cheapestPerFlight`); these are the others, kept so
/// the flight-detail screen can offer a real "Choose Your Fare" picker
/// instead of only ever showing the one fare the user happened to tap.
class FareFamilyIndexEntity extends Equatable {
  final String index;
  final double amount;
  final bool refundable;

  const FareFamilyIndexEntity({
    required this.index,
    required this.amount,
    required this.refundable,
  });

  @override
  List<Object?> get props => [index, amount, refundable];
}

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

  // Whether the fare shown (the cheapest fare-family variant of this
  // physical flight) is refundable, from the raw AkflightsModel's
  // Refundable flag. Null when the mapping site didn't have it available.
  final bool? refundable;

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

  // Sibling fare-class variants of this same physical flight (see
  // [FareFamilyIndexEntity]). Null/empty for the common case where the
  // flight only sells one fare, or when this FlightEntity wasn't produced
  // via the search-results grouping step.
  final List<FareFamilyIndexEntity>? fareFamilyOptions;

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
    this.refundable,
    this.isRoundTrip = false,
    this.returnDepartureTime,
    this.returnArrivalTime,
    this.returnDuration,
    this.returnOrigin,
    this.returnOriginName,
    this.returnDestination,
    this.returnDestinationName,
    this.returnStops,
    this.fareFamilyOptions,
  });

  FlightEntity copyWith({List<FareFamilyIndexEntity>? fareFamilyOptions}) {
    return FlightEntity(
      resultIndex: resultIndex,
      airlineCode: airlineCode,
      airlineName: airlineName,
      flightNumber: flightNumber,
      origin: origin,
      originName: originName,
      destination: destination,
      destinationName: destinationName,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      duration: duration,
      cabinClass: cabinClass,
      baseFare: baseFare,
      tax: tax,
      totalFare: totalFare,
      currency: currency,
      seatsAvailable: seatsAvailable,
      traceId: traceId,
      stops: stops,
      refundable: refundable,
      isRoundTrip: isRoundTrip,
      returnDepartureTime: returnDepartureTime,
      returnArrivalTime: returnArrivalTime,
      returnDuration: returnDuration,
      returnOrigin: returnOrigin,
      returnOriginName: returnOriginName,
      returnDestination: returnDestination,
      returnDestinationName: returnDestinationName,
      returnStops: returnStops,
      fareFamilyOptions: fareFamilyOptions ?? this.fareFamilyOptions,
    );
  }

  @override
  List<Object?> get props => [
    resultIndex, airlineCode, airlineName, flightNumber, origin, originName,
    destination, destinationName, departureTime, arrivalTime, duration, cabinClass,
    baseFare, tax, totalFare, currency, seatsAvailable, traceId, stops, refundable,
    isRoundTrip,
    returnDepartureTime, returnArrivalTime, returnDuration, returnOrigin,
    returnOriginName, returnDestination, returnDestinationName, returnStops,
    fareFamilyOptions,
  ];
}