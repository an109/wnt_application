// lib/features/hotel_details/presentation/bloc/hotel_details_event.dart
import 'package:equatable/equatable.dart';

abstract class HotelDetailsEvent extends Equatable {
  const HotelDetailsEvent();

  @override
  List<Object?> get props => [];
}

class FetchHotelDetailsEvent extends HotelDetailsEvent {
  final String hotelCode;
  final String checkIn;
  final String checkOut;
  final String? language;
  final String? guestNationality;

  const FetchHotelDetailsEvent({
    required this.hotelCode,
    required this.checkIn,
    required this.checkOut,
    this.language,
    this.guestNationality,
  });

  @override
  List<Object?> get props => [hotelCode, checkIn, checkOut, language, guestNationality];

  @override
  String toString() {
    return 'FetchHotelDetailsEvent(hotelCode: $hotelCode, checkIn: $checkIn, checkOut: $checkOut, language: $language, guestNationality: $guestNationality)';
  }
}