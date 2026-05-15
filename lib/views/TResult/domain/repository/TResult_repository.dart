import '../../../../core/error/data_state.dart';
import '../entity/TResult_entity.dart';

abstract class TransportResultRepository {
  Future<DataState<TransportResultEntity>> getTransportResult({
    required String searchId,
    required String resultId,
  });
}