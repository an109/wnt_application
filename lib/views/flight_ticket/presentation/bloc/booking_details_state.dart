import 'package:equatable/equatable.dart';
import '../../data/services/booking_details_service.dart';

abstract class BookingDetailsState extends Equatable {
  const BookingDetailsState();
  @override
  List<Object?> get props => [];
}

class BookingDetailsInitial extends BookingDetailsState {}

class BookingDetailsLoading extends BookingDetailsState {}

class BookingDetailsLoaded extends BookingDetailsState {
  final BookingDetailsModel details;
  const BookingDetailsLoaded(this.details);
  @override
  List<Object?> get props => [details];
}

class BookingDetailsError extends BookingDetailsState {
  final String message;
  const BookingDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}
