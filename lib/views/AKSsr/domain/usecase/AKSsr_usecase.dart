import '../../../../core/error/data_state.dart';
import '../entity/AKSsr_entity.dart';
import '../repository/AKSsr_repository.dart';

class AkSsrUseCase {
  final AkSsrRepository repository;

  AkSsrUseCase(this.repository);

  Future<DataState<AkSsrEntity>> call(AkSsrRequestEntity request) async {
    return await repository.getSsr(request);
  }
}
