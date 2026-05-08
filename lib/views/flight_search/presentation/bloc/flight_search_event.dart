import 'package:equatable/equatable.dart';
import '../../domain/entities/flight_search_request_entity.dart';

abstract class FlightSearchEvent extends Equatable {
  const FlightSearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchFlightsEvent extends FlightSearchEvent {
  final FlightSearchRequestEntity request;

  const SearchFlightsEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class ClearFlightsEvent extends FlightSearchEvent {
  const ClearFlightsEvent();
}