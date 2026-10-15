import '../../../../core/error/data_state.dart';
import '../entity/AKFareFamilyDetails_entity.dart';
import '../repository/AKFareFamilyDetails_repository.dart';

class AkFareFamilyDetailsUseCase {
  final AkFareFamilyDetailsRepository repository;

  AkFareFamilyDetailsUseCase(this.repository);

  Future<DataState<AkFareFamilyDetailsEntity>> call(
      AkFareFamilyDetailsRequestEntity request) async {
    return await repository.getFareFamilyDetails(request);
  }
}
