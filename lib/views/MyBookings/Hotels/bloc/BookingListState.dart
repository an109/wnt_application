import 'package:equatable/equatable.dart';

import '../domain/entity/HotelBookingEntity.dart';

abstract class HotelState extends Equatable {
  const HotelState();

  @override
  List<Object?> get props => [];
}

class HotelInitial extends HotelState {}

class HotelLoading extends HotelState {}

class HotelLoaded extends HotelState {
  final List<HotelBookingListEntity> bookings;

  const HotelLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class HotelError extends HotelState {
  final String message;

  const HotelError(this.message);

  @override
  List<Object?> get props => [message];
}