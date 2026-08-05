import '../../../../core/error/data_state.dart';
import '../entity/AKAcceptFareChange_entity.dart';
import '../repository/AKAcceptFareChange_repository.dart';

class AkAcceptFareChangeUseCase {
  final AkAcceptFareChangeRepository repository;

  AkAcceptFareChangeUseCase(this.repository);

  Future<DataState<AkAcceptFareChangeEntity>> call(
      AkAcceptFareChangeRequestEntity request) async {
    return await repository.acceptFareChange(request);
  }
}
