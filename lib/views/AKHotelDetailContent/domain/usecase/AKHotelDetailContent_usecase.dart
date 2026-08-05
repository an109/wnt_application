import '../../../../core/error/data_state.dart';
import '../entity/AKHotelDetailContent_entity.dart';
import '../repository/AKHotelDetailContent_repository.dart';

class AkHotelDetailContentUseCase {
  final AkHotelDetailContentRepository repository;

  AkHotelDetailContentUseCase(this.repository);

  Future<DataState<AkHotelDetailContentEntity>> call(AkHotelDetailContentRequestEntity request) async {
    return await repository.getHotelContent(request);
  }
}
