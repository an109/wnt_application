import 'package:equatable/equatable.dart';

// Enum for trip mode (type-safe)
enum TripMode { oneWay, roundTrip }

abstract class TransportSearchEvent extends Equatable {
  const TransportSearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchTransport extends TransportSearchEvent {
  final String startAddress;
  final String endAddress;
  final String pickupDatetime;
  final String? returnDatetime;
  final int numPassengers;
  final String currency;
  final TripMode mode;

  const SearchTransport({
    required this.startAddress,
    required this.endAddress,
    required this.pickupDatetime,
    this.returnDatetime,
    this.numPassengers = 1,
    this.currency = 'INR',
    this.mode = TripMode.oneWay,
  });

  // Helper to convert enum to API string value
  String get modeValue => mode == TripMode.oneWay ? 'one_way' : 'round_trip';

  @override
  List<Object?> get props => [
    startAddress,
    endAddress,
    pickupDatetime,
    returnDatetime,
    numPassengers,
    currency,
    mode,
  ];
}

class ClearTransportSearch extends TransportSearchEvent {
  const ClearTransportSearch();
}