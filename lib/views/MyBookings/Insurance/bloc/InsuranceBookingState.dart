import 'package:equatable/equatable.dart';
import '../domain/entity/InsuranceBookingEntity.dart';

abstract class InsuranceBookingState extends Equatable {
  const InsuranceBookingState();

  @override
  List<Object?> get props => [];
}

class InsuranceBookingInitial extends InsuranceBookingState {}

class InsuranceBookingLoading extends InsuranceBookingState {}

class InsuranceBookingLoaded extends InsuranceBookingState {
  final List<InsuranceBookingEntity> bookings;

  const InsuranceBookingLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class InsuranceBookingError extends InsuranceBookingState {
  final String message;

  const InsuranceBookingError(this.message);

  @override
  List<Object?> get props => [message];
}
