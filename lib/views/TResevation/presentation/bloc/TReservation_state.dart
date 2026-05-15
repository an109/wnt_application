import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/TReservation-entity.dart';

abstract class TransportReservationState extends Equatable {
  const TransportReservationState();

  @override
  List<Object?> get props => [];
}

class TransportReservationInitial extends TransportReservationState {
  const TransportReservationInitial();
}

class TransportReservationLoading extends TransportReservationState {
  const TransportReservationLoading();
}

class TransportReservationSuccess extends TransportReservationState {
  final TransportReservationEntity reservation;

  const TransportReservationSuccess(this.reservation);

  @override
  List<Object?> get props => [reservation];
}

class TransportReservationFailed extends TransportReservationState {
  final DataState<dynamic> dataState;

  const TransportReservationFailed(this.dataState);

  @override
  List<Object?> get props => [dataState];
}