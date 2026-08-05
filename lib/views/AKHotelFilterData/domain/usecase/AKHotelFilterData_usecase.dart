import '../../../../core/error/data_state.dart';
import '../entity/AKHotelFilterData_entity.dart';
import '../repository/AKHotelFilterData_repository.dart';

class AkHotelFilterDataUseCase {
  final AkHotelFilterDataRepository repository;

  AkHotelFilterDataUseCase(this.repository);

  Future<DataState<AkHotelFilterDataEntity>> call(AkHotelFilterDataRequestEntity request) async {
    return await repository.getFilterData(request);
  }
}
