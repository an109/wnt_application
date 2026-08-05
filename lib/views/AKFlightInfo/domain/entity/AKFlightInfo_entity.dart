import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkFlightInfoTripRequestEntity extends Equatable {
  final String index;
  final double amount;
  final int orderId;

  const AkFlightInfoTripRequestEntity({
    required this.index,
    required this.amount,
    required this.orderId,
  });

  @override
  List<Object?> get props => [index, amount, orderId];
}

class AkFlightInfoRequestEntity extends Equatable {
  final String tui;
  final String tripType;
  final List<AkFlightInfoTripRequestEntity> trips;

  const AkFlightInfoRequestEntity({
    required this.tui,
    required this.tripType,
    required this.trips,
  });

  @override
  List<Object?> get props => [tui, tripType, trips];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkFlightInfoFlightEntity extends Equatable {
  // Segment id used elsewhere (e.g. GetSPricer's included_baggage map) to
  // tie baggage/rules back to this specific flight leg.
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

  const AkFlightInfoFlightEntity({
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

class AkFlightInfoFareEntity extends Equatable {
  final double grossFare;
  final double netFare;
  final double totalBaseFare;
  final double totalTax;
  final double totalServiceTax;
  final double totalTransactionFee;
  final double totalCommission;

  const AkFlightInfoFareEntity({
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

class AkFlightInfoSegmentEntity extends Equatable {
  final AkFlightInfoFlightEntity flight;
  final AkFlightInfoFareEntity fare;

  const AkFlightInfoSegmentEntity({
    required this.flight,
    required this.fare,
  });

  @override
  List<Object?> get props => [flight, fare];
}

class AkFlightInfoJourneyEntity extends Equatable {
  final String provider;
  final int stops;
  final int orderId;
  final double grossFare;
  final double netFare;
  final String duration;
  final String promo;
  final String fareType;
  final List<AkFlightInfoSegmentEntity> segments;

  const AkFlightInfoJourneyEntity({
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

class AkFlightInfoTripEntity extends Equatable {
  final List<AkFlightInfoJourneyEntity> journey;

  const AkFlightInfoTripEntity({required this.journey});

  @override
  List<Object?> get props => [journey];
}

class AkFlightInfoEntity extends Equatable {
  final bool success;
  final String sessionId;
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
  final bool hold;
  final List<AkFlightInfoTripEntity> trips;

  const AkFlightInfoEntity({
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
    required this.hold,
    required this.trips,
  });

  @override
  List<Object?> get props => [
    success, sessionId, tui, from, to, fromName, toName, onwardDate,
    returnDate, adultCount, childCount, infantCount, netAmount, grossAmount,
    fareType, hold, trips,
  ];
}
