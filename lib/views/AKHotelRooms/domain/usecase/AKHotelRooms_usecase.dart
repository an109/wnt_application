import '../../../../core/error/data_state.dart';
import '../entity/AKHotelRooms_entity.dart';
import '../repository/AKHotelRooms_repository.dart';

class AkHotelRoomsUseCase {
  final AkHotelRoomsRepository repository;

  AkHotelRoomsUseCase(this.repository);

  Future<DataState<AkHotelRoomsResultEntity>> call(AkHotelRoomsRequestEntity request) async {
    return await repository.getRooms(request);
  }
}
