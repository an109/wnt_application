import '../../../../core/error/data_state.dart';
import '../entity/AKHotelRooms_entity.dart';

abstract class AkHotelRoomsRepository {
  Future<DataState<AkHotelRoomsResultEntity>> getRooms(AkHotelRoomsRequestEntity request);
}
