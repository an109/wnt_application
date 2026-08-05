import '../../../../core/error/data_state.dart';
import '../entity/AKTravelCheckList_entity.dart';
import '../repository/AKTravelCheckList_repository.dart';

class AkTravelCheckListUseCase {
  final AkTravelCheckListRepository repository;

  AkTravelCheckListUseCase(this.repository);

  Future<DataState<AkTravelCheckListEntity>> call(AkTravelCheckListRequestEntity request) async {
    return await repository.getTravelCheckList(request);
  }
}
