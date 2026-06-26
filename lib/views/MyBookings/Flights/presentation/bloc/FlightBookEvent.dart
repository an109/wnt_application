import 'package:equatable/equatable.dart';

abstract class FlightBookEvent extends Equatable {
  const FlightBookEvent();

  @override
  List<Object?> get props => [];
}

class FetchFlightBookings extends FlightBookEvent {
  final int? userId;

  const FetchFlightBookings({this.userId});

  @override
  List<Object?> get props => [userId];
}

class RefreshFlightBookings extends FlightBookEvent {
  final int? userId;

  const RefreshFlightBookings({this.userId});

  @override
  List<Object?> get props => [userId];
}