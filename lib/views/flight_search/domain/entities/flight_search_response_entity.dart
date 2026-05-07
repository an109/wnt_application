import 'package:equatable/equatable.dart';
import 'flight_entity.dart';

class FlightSearchResponseEntity extends Equatable {
  final String traceId;
  final String origin;
  final String destination;
  final List<FlightEntity> flights;
  final bool isSuccess;
  final String? errorMessage;

  const FlightSearchResponseEntity({
    required this.traceId,
    required this.origin,
    required this.destination,
    required this.flights,
    required this.isSuccess,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    traceId,
    origin,
    destination,
    flights,
    isSuccess,
    errorMessage,
  ];
}