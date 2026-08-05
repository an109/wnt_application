import '../../../../core/error/data_state.dart';
import '../entity/AKGetSPricer_entity.dart';
import '../repository/AKGetSPricer_repository.dart';

class AkGetSPricerUseCase {
  final AkGetSPricerRepository repository;

  AkGetSPricerUseCase(this.repository);

  Future<DataState<AkGetSPricerEntity>> call(
      AkGetSPricerRequestEntity request) async {
    return await repository.getSPricer(request);
  }
}
