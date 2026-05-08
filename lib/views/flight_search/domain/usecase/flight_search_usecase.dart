import '../../../../core/error/data_state.dart';
import '../entities/flight_entity.dart';
import '../entities/flight_search_request_entity.dart';
import '../repository/flight_repository.dart';

class SearchFlightsUseCase {
  final FlightRepository repository;

  SearchFlightsUseCase(this.repository);

  Future<DataState<List<FlightEntity>>> call(
      FlightSearchRequestEntity params) async {
    return await repository.searchFlights(params);
  }
}