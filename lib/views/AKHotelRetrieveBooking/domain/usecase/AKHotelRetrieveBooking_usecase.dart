import '../../../../core/error/data_state.dart';
import '../entity/AKHotelRetrieveBooking_entity.dart';
import '../repository/AKHotelRetrieveBooking_repository.dart';

class AkHotelRetrieveBookingUseCase {
  final AkHotelRetrieveBookingRepository repository;

  AkHotelRetrieveBookingUseCase(this.repository);

  Future<DataState<AkHotelRetrieveBookingEntity>> call(AkHotelRetrieveBookingRequestEntity request) async {
    return await repository.retrieveBooking(request);
  }
}
