import '../../../../core/error/data_state.dart';
import '../entities/booking_entity.dart';
import '../../data/models/booking_request_model.dart';

abstract class BookingRepository {
  Future<DataState<BookingEntity>> bookFlight(BookingRequestModel request);
}
