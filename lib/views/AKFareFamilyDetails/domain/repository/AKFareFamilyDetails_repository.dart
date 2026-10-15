import '../../../../core/error/data_state.dart';
import '../entity/AKFareFamilyDetails_entity.dart';

abstract class AkFareFamilyDetailsRepository {
  Future<DataState<AkFareFamilyDetailsEntity>> getFareFamilyDetails(
      AkFareFamilyDetailsRequestEntity request);
}
