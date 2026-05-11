import 'package:equatable/equatable.dart';

class FareQuoteEntity extends Equatable {
  final ResponseEntity? response;

  const FareQuoteEntity({this.response});

  @override
  List<Object?> get props => [response];
}

class ResponseEntity extends Equatable {
  final ErrorEntity? error;
  final bool? isPriceChanged;
  final int? responseStatus;
  final ResultsEntity? results;
  final String? traceId;

  const ResponseEntity({
    this.error,
    this.isPriceChanged,
    this.responseStatus,
    this.results,
    this.traceId,
  });

  @override
  List<Object?> get props => [
    error,
    isPriceChanged,
    responseStatus,
    results,
    traceId,
  ];
}

class ErrorEntity extends Equatable {
  final int? errorCode;
  final String? errorMessage;

  const ErrorEntity({this.errorCode, this.errorMessage});

  @override
  List<Object?> get props => [errorCode, errorMessage];
}

class ResultsEntity extends Equatable {
  final String? resultIndex;
  final bool? isRefundable;
  final bool? isHoldAllowed;
  final String? airlineCode;
  final String? resultFareType;
  final FareEntity? fare;
  final List<List<SegmentEntity>>? segments;

  const ResultsEntity({
    this.resultIndex,
    this.isRefundable,
    this.isHoldAllowed,
    this.airlineCode,
    this.resultFareType,
    this.fare,
    this.segments,
  });

  @override
  List<Object?> get props => [
    resultIndex,
    isRefundable,
    isHoldAllowed,
    airlineCode,
    resultFareType,
    fare,
    segments,
  ];
}

class FareEntity extends Equatable {
  final String? currency;
  final double? baseFare;
  final double? tax;
  final double? offeredFare;
  final double? publishedFare;

  const FareEntity({
    this.currency,
    this.baseFare,
    this.tax,
    this.offeredFare,
    this.publishedFare,
  });

  @override
  List<Object?> get props => [
    currency,
    baseFare,
    tax,
    offeredFare,
    publishedFare,
  ];
}

class SegmentEntity extends Equatable {
  final String? baggage;
  final AirlineEntity? airline;
  final AirportDetailEntity? origin;
  final AirportDetailEntity? destination;
  final int? duration;

  const SegmentEntity({
    this.baggage,
    this.airline,
    this.origin,
    this.destination,
    this.duration,
  });

  @override
  List<Object?> get props => [
    baggage,
    airline,
    origin,
    destination,
    duration,
  ];
}

class AirlineEntity extends Equatable {
  final String? airlineCode;
  final String? airlineName;
  final String? flightNumber;

  const AirlineEntity({
    this.airlineCode,
    this.airlineName,
    this.flightNumber,
  });

  @override
  List<Object?> get props => [airlineCode, airlineName, flightNumber];
}

class AirportDetailEntity extends Equatable {
  final String? airportCode;
  final String? airportName;
  final String? cityName;

  const AirportDetailEntity({
    this.airportCode,
    this.airportName,
    this.cityName,
  });

  @override
  List<Object?> get props => [airportCode, airportName, cityName];
}