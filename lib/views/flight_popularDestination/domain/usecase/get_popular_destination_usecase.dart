import '../../../../core/error/data_state.dart';
import '../entities/Popular_destination_entity.dart';
import '../repository/destination_repository.dart';

class GetPopularDestinationsUseCase {
  final PopularDestinationRepository repository;

  GetPopularDestinationsUseCase(this.repository);

  Future<DataState<List<DestinationEntity>>> call() async {
    return await repository.getPopularDestinations();
  }
}