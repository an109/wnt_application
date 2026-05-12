import '../../../../core/error/data_state.dart';
import '../entities/hotel_entity.dart';
import '../repository/hotel_repository.dart';

class GetHotelsByCityUseCase {
  final HotelRepository repository;

  GetHotelsByCityUseCase(this.repository);

  Future<DataState<List<HotelEntity>>> call({
    required String cityCode,
    required String checkIn,
    required String checkOut,
    required String guestNationality,
    required int page,
    required int pageSize,
    Map<String, dynamic>? filters,
    List<Map<String, dynamic>>? paxRooms,
  }) {
    return repository.getHotelsByCity(
      cityCode: cityCode,
      checkIn: checkIn,
      checkOut: checkOut,
      guestNationality: guestNationality,
      page: page,
      pageSize: pageSize,
      filters: filters,
      paxRooms: paxRooms,
    );
  }
}