import '../../../../core/error/data_state.dart';
import '../entity/TResult_entity.dart';
import '../repository/TResult_repository.dart';

class GetTransportResultUseCase {
  final TransportResultRepository repository;

  GetTransportResultUseCase(this.repository);

  Future<DataState<TransportResultEntity>> call({
    required String searchId,
    required String resultId,
  }) async {
    return await repository.getTransportResult(
      searchId: searchId,
      resultId: resultId,
    );
  }
}