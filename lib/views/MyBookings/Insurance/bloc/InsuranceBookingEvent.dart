import 'package:equatable/equatable.dart';

abstract class InsuranceBookingEvent extends Equatable {
  const InsuranceBookingEvent();

  @override
  List<Object?> get props => [];
}

class FetchInsuranceBookings extends InsuranceBookingEvent {}
