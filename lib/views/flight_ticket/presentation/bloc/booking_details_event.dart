import 'package:equatable/equatable.dart';

abstract class BookingDetailsEvent extends Equatable {
  const BookingDetailsEvent();
  @override
  List<Object?> get props => [];
}

class FetchBookingDetailsEvent extends BookingDetailsEvent {
  final String pnr;
  const FetchBookingDetailsEvent(this.pnr);
  @override
  List<Object?> get props => [pnr];
}
