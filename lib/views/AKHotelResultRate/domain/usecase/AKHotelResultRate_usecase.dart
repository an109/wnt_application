import '../../../../core/error/data_state.dart';
import '../entity/AKHotelResultRate_entity.dart';
import '../repository/AKHotelResultRate_repository.dart';

class AkHotelResultRateUseCase {
  final AkHotelResultRateRepository repository;

  AkHotelResultRateUseCase(this.repository);

  Future<DataState<AkHotelResultRateEntity>> call(AkHotelResultRateRequestEntity request) async {
    return await repository.getResultRate(request);
  }
}
