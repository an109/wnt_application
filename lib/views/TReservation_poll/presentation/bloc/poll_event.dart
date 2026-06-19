import 'package:equatable/equatable.dart';

abstract class ReservationPollEvent extends Equatable {
  const ReservationPollEvent();

  @override
  List<Object?> get props => [];
}

class FetchReservationPoll extends ReservationPollEvent {
  final String searchId;

  const FetchReservationPoll({required this.searchId});

  @override
  List<Object?> get props => [searchId];
}