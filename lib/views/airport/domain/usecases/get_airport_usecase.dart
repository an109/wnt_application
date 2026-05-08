import '../../../../core/error/data_state.dart';
import '../entities/airport_entities.dart';
import '../repository/airport_repositories.dart';

class GetAirportsUsecase {
  final AirportRepository repository;

  GetAirportsUsecase(this.repository);

  Future<DataState<List<AirportEntity>>> call({String? country,
    String? searchQuery,
  }) async {
    return await repository.getAirports(
        country: country,
        searchQuery: searchQuery,
    );
  }
}