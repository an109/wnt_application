import 'package:equatable/equatable.dart';

class SegmentEntity extends Equatable {
  final String origin;
  final String destination;
  final int flightCabinClass;
  final DateTime preferredDepartureTime;
  final DateTime preferredArrivalTime;

  const SegmentEntity({
    required this.origin,
    required this.destination,
    required this.flightCabinClass,
    required this.preferredDepartureTime,
    required this.preferredArrivalTime,
  });

  @override
  List<Object?> get props => [
    origin,
    destination,
    flightCabinClass,
    preferredDepartureTime,
    preferredArrivalTime,
  ];
}