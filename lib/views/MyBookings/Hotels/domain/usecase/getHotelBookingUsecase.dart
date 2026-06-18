

import '../../../../../core/error/data_state.dart';
import '../entity/HotelBookingEntity.dart';
import '../repository/HotelRepository.dart';

class GetHotelBookingsUseCase {
  final HotelListRepository _hotelRepository;

  GetHotelBookingsUseCase(this._hotelRepository);

  Future<DataState<List<HotelBookingListEntity>>> call() async {
    return await _hotelRepository.getHotelBookings();
  }
}