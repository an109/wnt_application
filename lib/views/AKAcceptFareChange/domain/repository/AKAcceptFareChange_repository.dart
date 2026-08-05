import '../../../../core/error/data_state.dart';
import '../entity/AKAcceptFareChange_entity.dart';

abstract class AkAcceptFareChangeRepository {
  Future<DataState<AkAcceptFareChangeEntity>> acceptFareChange(
      AkAcceptFareChangeRequestEntity request);
}
