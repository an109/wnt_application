import 'package:equatable/equatable.dart';

abstract class UpcomingTripEvent extends Equatable {
  const UpcomingTripEvent();

  @override
  List<Object?> get props => [];
}

class FetchUpcomingTrips extends UpcomingTripEvent {
  final String userEmail;

  const FetchUpcomingTrips({required this.userEmail});

  @override
  List<Object?> get props => [userEmail];
}