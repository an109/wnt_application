import 'package:equatable/equatable.dart';

abstract class HotelEvent extends Equatable {
  const HotelEvent();

  @override
  List<Object?> get props => [];
}

class FetchHotelBookings extends HotelEvent {
  const FetchHotelBookings();
}