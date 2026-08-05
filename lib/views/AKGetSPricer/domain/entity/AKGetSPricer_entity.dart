import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkGetSPricerRequestEntity extends Equatable {
  final String tui;

  // Same meaning as AkSmartPricerRequestEntity.preview — true for a
  // comparison/browsing call, so the backend doesn't overwrite
  // session.live_fare_response/net_amount with a fare the user hasn't
  // actually committed to. False only for the final commit right before
  // Book Now proceeds.
  final bool preview;

  const AkGetSPricerRequestEntity({
    required this.tui,
    this.preview = false,
  });

  @override
  List<Object?> get props => [tui, preview];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkGetSPricerFlightEntity extends Equatable {
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

  const AkGetSPricerFlightEntity({
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

class AkGetSPricerFareEntity extends Equatable {
  final double grossFare;
  final double netFare;
  final double totalBaseFare;
  final double totalTax;
  final double totalServiceTax;
  final double totalTransactionFee;
  final double totalCommission;

  const AkGetSPricerFareEntity({
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

class AkGetSPricerSegmentEntity extends Equatable {
  final AkGetSPricerFlightEntity flight;
  final AkGetSPricerFareEntity fare;

  const AkGetSPricerSegmentEntity({
    required this.flight,
    required this.fare,
  });

  @override
  List<Object?> get props => [flight, fare];
}

class AkGetSPricerJourneyEntity extends Equatable {
  final String provider;
  final int stops;
  final int orderId;
  final double grossFare;
  final double netFare;
  final String duration;
  final String promo;
  final String fareType;
  final List<AkGetSPricerSegmentEntity> segments;

  const AkGetSPricerJourneyEntity({
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

class AkGetSPricerTripEntity extends Equatable {
  final List<AkGetSPricerJourneyEntity> journey;

  const AkGetSPricerTripEntity({required this.journey});

  @override
  List<Object?> get props => [journey];
}

/// Baggage allowance for one passenger type (e.g. "ADT") on one segment.
class AkGetSPricerBaggageEntity extends Equatable {
  final String checkin;
  final String cabin;

  const AkGetSPricerBaggageEntity({
    required this.checkin,
    required this.cabin,
  });

  @override
  List<Object?> get props => [checkin, cabin];
}

class AkGetSPricerEntity extends Equatable {
  final bool success;
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
  // True when the fare changed between the earlier FlightInfo call and this
  // re-price — the UI should flag this before letting the user book.
  final bool fareChanged;
  // Keyed by FUID (segment id, as a string) -> passenger type (e.g. "ADT").
  final Map<String, Map<String, AkGetSPricerBaggageEntity>> includedBaggage;
  final List<AkGetSPricerTripEntity> trips;

  const AkGetSPricerEntity({
    required this.success,
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
    required this.fareChanged,
    required this.includedBaggage,
    required this.trips,
  });

  @override
  List<Object?> get props => [
    success, tui, from, to, fromName, toName, onwardDate, returnDate,
    adultCount, childCount, infantCount, netAmount, grossAmount, fareType,
    fareChanged, includedBaggage, trips,
  ];
}
