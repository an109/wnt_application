import 'package:equatable/equatable.dart';
import '../../domain/entities/hotel_booking_entity.dart';

abstract class HotelBookingState extends Equatable {
  const HotelBookingState();

  @override
  List<Object?> get props => [];
}

class HotelBookingInitial extends HotelBookingState {
  const HotelBookingInitial();
}

class HotelBookingLoading extends HotelBookingState {
  const HotelBookingLoading();
}

class HotelBookingLoaded extends HotelBookingState {
  final HotelBookingEntity hotelBooking;

  const HotelBookingLoaded(this.hotelBooking);

  @override
  List<Object?> get props => [hotelBooking];
}

class HotelBookingError extends HotelBookingState {
  final String errorMessage;

  const HotelBookingError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}