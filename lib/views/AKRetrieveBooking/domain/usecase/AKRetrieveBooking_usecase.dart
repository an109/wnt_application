import '../../../../core/error/data_state.dart';
import '../entity/AKRetrieveBooking_entity.dart';
import '../repository/AKRetrieveBooking_repository.dart';

class AkRetrieveBookingUseCase {
  final AkRetrieveBookingRepository repository;

  AkRetrieveBookingUseCase(this.repository);

  Future<DataState<AkRetrieveBookingEntity>> call(AkRetrieveBookingRequestEntity request) async {
    return await repository.retrieveBooking(request);
  }
}
