import '../../../../../core/error/data_state.dart';
import '../entity/MyBooking_entity.dart';
import '../repository/MyBooking_repository.dart';

class GetBookingsUseCase {
  final MyBookingRepository _bookingRepository;

  GetBookingsUseCase(this._bookingRepository);

  Future<DataState<List<BookingEntity>>> call() async {
    return await _bookingRepository.getBookings();
  }
}