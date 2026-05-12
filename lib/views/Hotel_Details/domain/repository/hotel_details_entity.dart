import '../../../../core/error/data_state.dart';
import '../entities/hotel_details_entity.dart';

abstract class HotelDetailsRepository {
  Future<DataState<List<HotelDetailsEntity>>> getHotelDetails({
    required String hotelCode,
    required String checkIn,
    required String checkOut,
    String? language,
    String? guestNationality,
  });
}