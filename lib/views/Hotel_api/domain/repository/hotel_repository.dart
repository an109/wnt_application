import '../../../../core/error/data_state.dart';
import '../entities/hotel_entity.dart';

abstract class HotelRepository {
  Future<DataState<List<HotelEntity>>> getHotelsByCity({
    required String cityCode,
    required String checkIn,
    required String checkOut,
    required String guestNationality,
    required int page,
    required int pageSize,
    Map<String, dynamic>? filters,
    List<Map<String, dynamic>>? paxRooms,
  });
}