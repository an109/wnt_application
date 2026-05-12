import '../../../../core/error/data_state.dart';
import '../../data/models/destination_model.dart';
import '../../domain/repository/destination_repository.dart';

class SearchDestinationsUseCase {
  final DestinationRepository repository;

  SearchDestinationsUseCase(this.repository);

  Future<DataState<DestinationSearchModel>> execute({
    required String query,
    String? countryCode,
    int limit = 100,
  }) async {
    return await repository.searchDestinations(
      query: query,
      countryCode: countryCode,
      limit: limit,
    );
  }
}