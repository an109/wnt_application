import 'package:equatable/equatable.dart';
import '../../domain/entity/AKRetrieveBooking_entity.dart';

abstract class AkRetrieveBookingEvent extends Equatable {
  const AkRetrieveBookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkRetrieveBookingEvent extends AkRetrieveBookingEvent {
  final AkRetrieveBookingRequestEntity request;

  const LoadAkRetrieveBookingEvent(this.request);

  @override
  List<Object?> get props => [request];
}
