import '../../../../core/error/data_state.dart';
import '../entity/AKHotelPrice_entity.dart';
import '../repository/AKHotelPrice_repository.dart';

class AkHotelPriceUseCase {
  final AkHotelPriceRepository repository;

  AkHotelPriceUseCase(this.repository);

  Future<DataState<AkHotelPriceEntity>> call(AkHotelPriceRequestEntity request) async {
    return await repository.getPrice(request);
  }
}
