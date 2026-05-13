import '../../../../core/error/data_state.dart';
import '../entities/hotel_booking_entity.dart';

abstract class HotelBookingRepository {
  Future<DataState<HotelBookingEntity>> getHotelBookingDetails({
    required String bookingCode,
    required String paymentMode,
  });
}