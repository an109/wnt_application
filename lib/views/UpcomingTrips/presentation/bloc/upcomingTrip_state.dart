import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/upcomingTrip_entity.dart';

abstract class UpcomingTripState extends Equatable {
  const UpcomingTripState();

  @override
  List<Object?> get props => [];
}

class UpcomingTripInitial extends UpcomingTripState {}

class UpcomingTripLoading extends UpcomingTripState {}

class UpcomingTripLoaded extends UpcomingTripState {
  final List<UpcomingTripEntity> trips;

  const UpcomingTripLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

class UpcomingTripError extends UpcomingTripState {
  final DioException error;

  const UpcomingTripError(this.error);

  @override
  List<Object?> get props => [error];
}