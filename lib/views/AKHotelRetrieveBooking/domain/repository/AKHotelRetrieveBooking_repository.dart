import '../../../../core/error/data_state.dart';
import '../entity/AKHotelRetrieveBooking_entity.dart';

abstract class AkHotelRetrieveBookingRepository {
  Future<DataState<AkHotelRetrieveBookingEntity>> retrieveBooking(AkHotelRetrieveBookingRequestEntity request);
}
