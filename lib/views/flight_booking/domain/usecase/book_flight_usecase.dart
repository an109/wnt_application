import '../../../../core/error/data_state.dart';
import '../../data/models/booking_request_model.dart';
import '../entities/booking_entity.dart';
import '../repository/booking_repository.dart';

class BookFlightUsecase {
  final BookingRepository repository;

  BookFlightUsecase(this.repository);

  Future<DataState<BookingEntity>> call(BookingRequestModel request) {
    return repository.bookFlight(request);
  }
}
