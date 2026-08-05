import '../../../../core/error/data_state.dart';
import '../entity/AKHotelResultContent_entity.dart';
import '../repository/AKHotelResultContent_repository.dart';

class AkHotelResultContentUseCase {
  final AkHotelResultContentRepository repository;

  AkHotelResultContentUseCase(this.repository);

  Future<DataState<AkHotelResultContentEntity>> call(AkHotelResultContentRequestEntity request) async {
    return await repository.getResultContent(request);
  }
}
