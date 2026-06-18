import '../../../../../core/error/data_state.dart';
import '../entity/MyBooking_entity.dart';


abstract class MyBookingRepository {
  Future<DataState<List<BookingEntity>>> getBookings();
}