import 'package:equatable/equatable.dart';

class AkFlightSearchEntity extends Equatable {
  final bool success;
  final String tui;
  final String sessionId;

  const AkFlightSearchEntity({
    required this.success,
    required this.tui,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [success, tui, sessionId];
}

class TripEntity extends Equatable {
  final String from;
  final String to;
  final String onwardDate;
  final String? returnDate;

  const TripEntity({
    required this.from,
    required this.to,
    required this.onwardDate,
    this.returnDate,
  });

  @override
  List<Object?> get props => [from, to, onwardDate, returnDate];
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