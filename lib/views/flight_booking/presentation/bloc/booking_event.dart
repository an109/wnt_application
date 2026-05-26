import 'package:equatable/equatable.dart';
import '../../data/models/booking_request_model.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class BookFlightEvent extends BookingEvent {
  final BookingRequestModel request;
  const BookFlightEvent(this.request);
  @override
  List<Object?> get props => [request];
}
