import 'package:equatable/equatable.dart';
import '../../domain/entities/hotel_details_entity.dart';

abstract class HotelDetailsState extends Equatable {
  const HotelDetailsState();

  @override
  List<Object?> get props => [];
}

class HotelDetailsInitial extends HotelDetailsState {
  const HotelDetailsInitial();
}

class HotelDetailsLoading extends HotelDetailsState {
  const HotelDetailsLoading();
}

class HotelDetailsLoaded extends HotelDetailsState {
  final List<HotelDetailsEntity> hotelDetails;

  const HotelDetailsLoaded(this.hotelDetails);

  @override
  List<Object?> get props => [hotelDetails];

  @override
  String toString() {
    return 'HotelDetailsLoaded(hotelDetails: ${hotelDetails.length} items)';
  }
}

class HotelDetailsError extends HotelDetailsState {
  final String message;

  const HotelDetailsError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() {
    return 'HotelDetailsError(message: $message)';
  }
}