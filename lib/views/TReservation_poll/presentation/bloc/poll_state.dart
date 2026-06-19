import 'package:equatable/equatable.dart';
import '../../domain/entity/poll_entity.dart';

abstract class ReservationPollState extends Equatable {
  const ReservationPollState();

  @override
  List<Object?> get props => [];
}

class ReservationPollInitial extends ReservationPollState {}

class ReservationPollLoading extends ReservationPollState {}

class ReservationPollSuccess extends ReservationPollState {
  final ReservationPollEntity reservationPoll;

  const ReservationPollSuccess(this.reservationPoll);

  @override
  List<Object?> get props => [reservationPoll];
}

class ReservationPollFailed extends ReservationPollState {
  final String error;

  const ReservationPollFailed(this.error);

  @override
  List<Object?> get props => [error];
}