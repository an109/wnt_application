import '../../../../core/error/data_state.dart';
import '../entity/AKSelectSeats_entity.dart';
import '../repository/AKSelectSeats_repository.dart';

class AkSelectSeatsUseCase {
  final AkSelectSeatsRepository repository;

  AkSelectSeatsUseCase(this.repository);

  Future<DataState<AkSelectSeatsEntity>> call(AkSelectSeatsRequestEntity request) async {
    return await repository.selectSeats(request);
  }
}
