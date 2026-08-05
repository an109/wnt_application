import '../../../../core/error/data_state.dart';
import '../entity/AKSeatLayout_entity.dart';
import '../repository/AKSeatLayout_repository.dart';

class AkSeatLayoutUseCase {
  final AkSeatLayoutRepository repository;

  AkSeatLayoutUseCase(this.repository);

  Future<DataState<AkSeatLayoutEntity>> call(AkSeatLayoutRequestEntity request) async {
    return await repository.getSeatLayout(request);
  }
}
