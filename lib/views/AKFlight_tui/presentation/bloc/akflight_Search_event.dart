import 'package:equatable/equatable.dart';
import '../../domain/entity/akflight_search_entity.dart';

abstract class AkFlightSearchEvent extends Equatable {
  const AkFlightSearchEvent();

  @override
  List<Object?> get props => [];
}

class AkFlightSearchInitEvent extends AkFlightSearchEvent {
  const AkFlightSearchInitEvent();
}

class AkFlightSearchExecuteEvent extends AkFlightSearchEvent {
  final FlightSearchRequestEntity request;

  const AkFlightSearchExecuteEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class AkFlightSearchResetEvent extends AkFlightSearchEvent {
  const AkFlightSearchResetEvent();
}