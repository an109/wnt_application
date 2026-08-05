import '../../../../core/error/data_state.dart';
import '../entity/AKRetrieveBooking_entity.dart';

abstract class AkRetrieveBookingRepository {
  Future<DataState<AkRetrieveBookingEntity>> retrieveBooking(
      AkRetrieveBookingRequestEntity request);
}
