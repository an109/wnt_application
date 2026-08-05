import '../../../../core/error/data_state.dart';
import '../entity/AKSmartPricer_entity.dart';

abstract class AkSmartPricerRepository {
  Future<DataState<AkSmartPricerEntity>> getSmartPricer(
      AkSmartPricerRequestEntity request);
}
