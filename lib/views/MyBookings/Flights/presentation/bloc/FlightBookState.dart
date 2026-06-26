import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/FlightBookEntity.dart';

abstract class FlightBookState extends Equatable {
  const FlightBookState();

  @override
  List<Object?> get props => [];
}

class FlightBookInitial extends FlightBookState {
  const FlightBookInitial();
}

class FlightBookLoading extends FlightBookState {
  const FlightBookLoading();
}

class FlightBookLoaded extends FlightBookState {
  final List<FlightBookEntity> bookings;

  const FlightBookLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class FlightBookError extends FlightBookState {
  final DioException error;

  const FlightBookError(this.error);

  @override
  List<Object?> get props => [error];
}