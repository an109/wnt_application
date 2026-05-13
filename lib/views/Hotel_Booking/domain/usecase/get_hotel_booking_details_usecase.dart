import '../../../../core/error/data_state.dart';
import '../entities/hotel_booking_entity.dart';
import '../repository/hotel_booking_repository.dart';

class GetHotelBookingDetailsUseCase {
  final HotelBookingRepository repository;

  GetHotelBookingDetailsUseCase(this.repository);

  Future<DataState<HotelBookingEntity>> call({
    required String bookingCode,
    required String paymentMode,
  }) async {
    return await repository.getHotelBookingDetails(
      bookingCode: bookingCode,
      paymentMode: paymentMode,
    );
  }
}