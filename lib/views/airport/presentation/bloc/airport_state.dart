import 'package:equatable/equatable.dart';
import '../../domain/entities/airport_entities.dart';

abstract class AirportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AirportInitial extends AirportState {}

class AirportLoading extends AirportState {}

class AirportLoaded extends AirportState {
  final List<AirportEntity> airports;

  AirportLoaded(this.airports);

  @override
  List<Object?> get props => [airports];
}

class AirportError extends AirportState {
  final String message;

  AirportError(this.message);

  @override
  List<Object?> get props => [message];
}