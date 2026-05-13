import 'package:equatable/equatable.dart';

abstract class HotelBookingEvent extends Equatable {
  const HotelBookingEvent();

  @override
  List<Object?> get props => [];
}

class GetHotelBookingDetailsEvent extends HotelBookingEvent {
  final String bookingCode;
  final String paymentMode;

  const GetHotelBookingDetailsEvent({
    required this.bookingCode,
    required this.paymentMode,
  });

  @override
  List<Object?> get props => [bookingCode, paymentMode];
}