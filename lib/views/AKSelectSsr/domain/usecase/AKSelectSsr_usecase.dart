import '../../../../core/error/data_state.dart';
import '../entity/AKSelectSsr_entity.dart';
import '../repository/AKSelectSsr_repository.dart';

class AkSelectSsrUseCase {
  final AkSelectSsrRepository repository;

  AkSelectSsrUseCase(this.repository);

  Future<DataState<AkSelectSsrEntity>> call(AkSelectSsrRequestEntity request) async {
    return await repository.selectSsr(request);
  }
}
