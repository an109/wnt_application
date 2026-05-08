import 'package:equatable/equatable.dart';
import '../../domain/entities/flight_entity.dart';

abstract class FlightSearchState extends Equatable {
  const FlightSearchState();

  @override
  List<Object?> get props => [];
}

class FlightSearchInitial extends FlightSearchState {}

class FlightSearchLoading extends FlightSearchState {}

class FlightSearchLoaded extends FlightSearchState {
  final List<FlightEntity> flights;
  final String? traceId;
  final String? origin;
  final String? destination;

  const FlightSearchLoaded({
    required this.flights,
    this.traceId,
    this.origin,
    this.destination,
  });

  @override
  List<Object?> get props => [flights, traceId, origin, destination];
}

class FlightSearchError extends FlightSearchState {
  final String message;

  const FlightSearchError(this.message);

  @override
  List<Object?> get props => [message];
}