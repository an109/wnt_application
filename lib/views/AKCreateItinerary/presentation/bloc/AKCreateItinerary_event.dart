import 'package:equatable/equatable.dart';
import '../../domain/entity/AKCreateItinerary_entity.dart';

abstract class AkCreateItineraryEvent extends Equatable {
  const AkCreateItineraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadAkCreateItineraryEvent extends AkCreateItineraryEvent {
  final AkCreateItineraryRequestEntity request;

  const LoadAkCreateItineraryEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ResetAkCreateItineraryEvent extends AkCreateItineraryEvent {
  const ResetAkCreateItineraryEvent();
}
