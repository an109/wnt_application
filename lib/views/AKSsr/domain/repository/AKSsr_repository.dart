import '../../../../core/error/data_state.dart';
import '../entity/AKSsr_entity.dart';

abstract class AkSsrRepository {
  Future<DataState<AkSsrEntity>> getSsr(AkSsrRequestEntity request);
}
