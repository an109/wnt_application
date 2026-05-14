import '../../../../core/error/data_state.dart';
import '../entities/T_SearchEntity.dart';

abstract class TransportSearchRepository {
  Future<DataState<TransportSearchEntity>> searchTransport({
    required String startAddress,
    required String endAddress,
    required String pickupDatetime,
    required int numPassengers,
    required String currency,
    required String mode,
  });
}