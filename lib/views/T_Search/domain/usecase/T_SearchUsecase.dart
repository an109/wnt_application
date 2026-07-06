import '../../../../core/error/data_state.dart';
import '../entities/T_SearchEntity.dart';
import '../repository/T_SearchRepository.dart';

class TransportSearchUsecase {
  final TransportSearchRepository repository;

  TransportSearchUsecase(this.repository);

  Future<DataState<TransportSearchEntity>> execute({
    required String startAddress,
    required String endAddress,
    required String pickupDatetime,
    String? returnPickupDatetime,
    required int numPassengers,
    required String currency,
    required String mode,
  }) {
    return repository.searchTransport(
      startAddress: startAddress,
      endAddress: endAddress,
      pickupDatetime: pickupDatetime,
      returnPickupDatetime: returnPickupDatetime,
      numPassengers: numPassengers,
      currency: currency,
      mode: mode,
    );
  }
}