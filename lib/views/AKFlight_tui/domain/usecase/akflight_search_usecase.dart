import '../../../../core/error/data_state.dart';
import '../entity/akflight_search_entity.dart';
import '../repository/akflight_Search_repository.dart';

class AkFlightSearchUseCase {
  final AkFlightSearchRepository repository;

  AkFlightSearchUseCase(this.repository);

  Future<DataState<AkFlightSearchEntity>> call(FlightSearchRequestEntity params) async {
    return await repository.searchFlights(params);
  }
}