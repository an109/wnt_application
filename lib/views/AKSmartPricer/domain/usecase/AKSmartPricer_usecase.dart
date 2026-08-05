import '../../../../core/error/data_state.dart';
import '../entity/AKSmartPricer_entity.dart';
import '../repository/AKSmartPricer_repository.dart';

class AkSmartPricerUseCase {
  final AkSmartPricerRepository repository;

  AkSmartPricerUseCase(this.repository);

  Future<DataState<AkSmartPricerEntity>> call(
      AkSmartPricerRequestEntity request) async {
    return await repository.getSmartPricer(request);
  }
}
