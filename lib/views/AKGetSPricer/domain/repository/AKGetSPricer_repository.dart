import '../../../../core/error/data_state.dart';
import '../entity/AKGetSPricer_entity.dart';

abstract class AkGetSPricerRepository {
  Future<DataState<AkGetSPricerEntity>> getSPricer(
      AkGetSPricerRequestEntity request);
}
