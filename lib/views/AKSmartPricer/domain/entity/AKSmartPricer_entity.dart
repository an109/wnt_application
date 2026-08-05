import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkSmartPricerTripRequestEntity extends Equatable {
  final String index;
  final double amount;
  final int orderId;

  const AkSmartPricerTripRequestEntity({
    required this.index,
    required this.amount,
    required this.orderId,
  });

  @override
  List<Object?> get props => [index, amount, orderId];
}

class AkSmartPricerRequestEntity extends Equatable {
  // The tui returned by FlightInfo — SmartPricer re-prices using it and
  // returns a fresh tui that GetSPricer must be called with.
  final String searchTui;
  final String tripType;
  final List<AkSmartPricerTripRequestEntity> trips;

  // True for any call that isn't the customer's actual booking choice —
  // comparing fare families, or a flight the user is only browsing. The
  // backend skips writing session.pricing_tui when this is true, so an
  // unrelated preview can never end up being what CreateItinerary books
  // ("the last preview to finish would decide the booking" otherwise).
  // False (commit) must only be sent once, right before proceeding past
  // Book Now, for whichever fare is actually selected at that moment.
  final bool preview;

  const AkSmartPricerRequestEntity({
    required this.searchTui,
    required this.tripType,
    required this.trips,
    this.preview = false,
  });

  @override
  List<Object?> get props => [searchTui, tripType, trips, preview];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkSmartPricerFlightEntity extends Equatable {
  // Segment id, matched against includedBaggage's keys.
  final int fuid;
  final String vac;
  final String mac;
  final String oac;
  final String fbc;
  // "ValidatingName|MarketingName|OperatingName"
  final String airline;
  final String flightNo;
  final String departureTime;
  final String arrivalTime;
  final String fareClass;
  final String departureCode;
  final String arrivalCode;
  final String departureTerminal;
  final String arrivalTerminal;
  final String depAirportName;
  final String arrAirportName;
  final String equipmentType;
  final String aircraft;
  final String rbd;
  final String cabin;
  final String refundable;
  final int seats;
  final String duration;

  const AkSmartPricerFlightEntity({
    required this.fuid,
    required this.vac,
    required this.mac,
    required this.oac,
    required this.fbc,
    required this.airline,
    required this.flightNo,
    required this.departureTime,
    required this.arrivalTime,
    required this.fareClass,
    required this.departureCode,
    required this.arrivalCode,
    required this.departureTerminal,
    required this.arrivalTerminal,
    required this.depAirportName,
    required this.arrAirportName,
    required this.equipmentType,
    required this.aircraft,
    required this.rbd,
    required this.cabin,
    required this.refundable,
    required this.seats,
    required this.duration,
  });

  @override
  List<Object?> get props => [
    fuid, vac, mac, oac, fbc, airline, flightNo, departureTime, arrivalTime,
    fareClass, departureCode, arrivalCode, departureTerminal, arrivalTerminal,
    depAirportName, arrAirportName, equipmentType, aircraft, rbd, cabin,
    refundable, seats, duration,
  ];
}

class AkSmartPricerFareEntity extends Equatable {
  final double grossFare;
  final double netFare;
  final double totalBaseFare;
  final double totalTax;
  final double totalServiceTax;
  final double totalTransactionFee;
  final double totalCommission;

  const AkSmartPricerFareEntity({
    required this.grossFare,
    required this.netFare,
    required this.totalBaseFare,
    required this.totalTax,
    required this.totalServiceTax,
    required this.totalTransactionFee,
    required this.totalCommission,
  });

  @override
  List<Object?> get props => [
    grossFare, netFare, totalBaseFare, totalTax, totalServiceTax,
    totalTransactionFee, totalCommission,
  ];
}

class AkSmartPricerSegmentEntity extends Equatable {
  final AkSmartPricerFlightEntity flight;
  final AkSmartPricerFareEntity fare;

  const AkSmartPricerSegmentEntity({
    required this.flight,
    required this.fare,
  });

  @override
  List<Object?> get props => [flight, fare];
}

class AkSmartPricerJourneyEntity extends Equatable {
  final String provider;
  final int stops;
  final int orderId;
  final double grossFare;
  final double netFare;
  final String duration;
  final String promo;
  final String fareType;
  final List<AkSmartPricerSegmentEntity> segments;

  const AkSmartPricerJourneyEntity({
    required this.provider,
    required this.stops,
    required this.orderId,
    required this.grossFare,
    required this.netFare,
    required this.duration,
    required this.promo,
    required this.fareType,
    required this.segments,
  });

  @override
  List<Object?> get props => [
    provider, stops, orderId, grossFare, netFare, duration, promo, fareType,
    segments,
  ];
}

class AkSmartPricerTripEntity extends Equatable {
  final List<AkSmartPricerJourneyEntity> journey;

  const AkSmartPricerTripEntity({required this.journey});

  @override
  List<Object?> get props => [journey];
}

/// Baggage allowance for one passenger type (e.g. "ADT") on one segment.
class AkSmartPricerBaggageEntity extends Equatable {
  final String checkin;
  final String cabin;

  const AkSmartPricerBaggageEntity({
    required this.checkin,
    required this.cabin,
  });

  @override
  List<Object?> get props => [checkin, cabin];
}

class AkSmartPricerEntity extends Equatable {
  final bool success;
  final String sessionId;
  // The re-priced tui — must be passed to GetSPricer to fetch live fare.
  final String tui;
  final String from;
  final String to;
  final String fromName;
  final String toName;
  final String onwardDate;
  final String? returnDate;
  final int adultCount;
  final int childCount;
  final int infantCount;
  final double netAmount;
  final double grossAmount;
  final String fareType;
  // Keyed by FUID (segment id, as a string) -> passenger type (e.g. "ADT").
  final Map<String, Map<String, AkSmartPricerBaggageEntity>> includedBaggage;
  final List<AkSmartPricerTripEntity> trips;

  const AkSmartPricerEntity({
    required this.success,
    required this.sessionId,
    required this.tui,
    required this.from,
    required this.to,
    required this.fromName,
    required this.toName,
    required this.onwardDate,
    this.returnDate,
    required this.adultCount,
    required this.childCount,
    required this.infantCount,
    required this.netAmount,
    required this.grossAmount,
    required this.fareType,
    required this.includedBaggage,
    required this.trips,
  });

  @override
  List<Object?> get props => [
    success, sessionId, tui, from, to, fromName, toName, onwardDate, returnDate,
    adultCount, childCount, infantCount, netAmount, grossAmount, fareType,
    includedBaggage, trips,
  ];
}
