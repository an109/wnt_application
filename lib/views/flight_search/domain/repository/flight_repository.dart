import '../../../../core/error/data_state.dart';
import '../entities/flight_entity.dart';
import '../entities/flight_search_request_entity.dart';

abstract class FlightRepository {
  Future<DataState<List<FlightEntity>>> searchFlights(
      FlightSearchRequestEntity request);
}