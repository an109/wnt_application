import 'package:equatable/equatable.dart';

class AkFlightSearchEntity extends Equatable {
  final bool success;
  final String tui;
  final String sessionId;
  // For DM (domestic multi-city): one TUI per leg, in order.
  // Empty for ON/RT/RS/IM — those use the single [tui] above.
  final List<String> tuis;

  const AkFlightSearchEntity({
    required this.success,
    required this.tui,
    required this.sessionId,
    this.tuis = const [],
  });

  @override
  List<Object?> get props => [success, tui, sessionId, tuis];
}

class TripEntity extends Equatable {
  final String from;
  final String to;
  final String onwardDate;
  final String? returnDate;

  // Required by Akbar for DM and IM (see API doc).
  final String? fromCity;
  final String? toCity;
  final String? fromArptName;
  final String? toArptName;

  // IM-only fields.
  final int? orderId;
  final String? onwardCabin;

  const TripEntity({
    required this.from,
    required this.to,
    required this.onwardDate,
    this.returnDate,
    this.fromCity,
    this.toCity,
    this.fromArptName,
    this.toArptName,
    this.orderId,
    this.onwardCabin,
  });

  @override
  List<Object?> get props => [
    from, to, onwardDate, returnDate,
    fromCity, toCity, fromArptName, toArptName,
    orderId, onwardCabin,
  ];
}

class FlightSearchRequestEntity extends Equatable {
  final int adults;
  final int children;
  final int infants;
  final String cabin;
  final String fareType;
  final List<TripEntity> trips;

  const FlightSearchRequestEntity({
    required this.adults,
    required this.children,
    required this.infants,
    required this.cabin,
    required this.fareType,
    required this.trips,
  });

  @override
  List<Object?> get props => [
    adults,
    children,
    infants,
    cabin,
    fareType,
    trips,
  ];
}