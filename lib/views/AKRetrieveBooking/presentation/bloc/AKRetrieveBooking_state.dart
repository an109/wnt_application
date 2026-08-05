import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entity/AKRetrieveBooking_entity.dart';

abstract class AkRetrieveBookingState extends Equatable {
  const AkRetrieveBookingState();

  @override
  List<Object?> get props => [];
}

class AkRetrieveBookingInitial extends AkRetrieveBookingState {
  const AkRetrieveBookingInitial();
}

class AkRetrieveBookingLoading extends AkRetrieveBookingState {
  const AkRetrieveBookingLoading();
}

class AkRetrieveBookingLoaded extends AkRetrieveBookingState {
  final AkRetrieveBookingEntity data;

  const AkRetrieveBookingLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AkRetrieveBookingFailed extends AkRetrieveBookingState {
  final DioException error;

  const AkRetrieveBookingFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
