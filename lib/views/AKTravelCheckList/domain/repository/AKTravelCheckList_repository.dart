import '../../../../core/error/data_state.dart';
import '../entity/AKTravelCheckList_entity.dart';

abstract class AkTravelCheckListRepository {
  Future<DataState<AkTravelCheckListEntity>> getTravelCheckList(
      AkTravelCheckListRequestEntity request);
}
