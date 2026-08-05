import '../../../../core/error/data_state.dart';
import '../entity/AKHotelSearchInit_entity.dart';
import '../repository/AKHotelSearchInit_repository.dart';

class AkHotelSearchInitUseCase {
  final AkHotelSearchInitRepository repository;

  AkHotelSearchInitUseCase(this.repository);

  Future<DataState<AkHotelSearchInitEntity>> call(AkHotelSearchInitRequestEntity request) async {
    return await repository.searchInit(request);
  }
}
