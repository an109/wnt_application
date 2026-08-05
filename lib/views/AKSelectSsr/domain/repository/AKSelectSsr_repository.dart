import '../../../../core/error/data_state.dart';
import '../entity/AKSelectSsr_entity.dart';

abstract class AkSelectSsrRepository {
  Future<DataState<AkSelectSsrEntity>> selectSsr(AkSelectSsrRequestEntity request);
}
