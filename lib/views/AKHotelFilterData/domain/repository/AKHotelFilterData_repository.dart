import '../../../../core/error/data_state.dart';
import '../entity/AKHotelFilterData_entity.dart';

abstract class AkHotelFilterDataRepository {
  Future<DataState<AkHotelFilterDataEntity>> getFilterData(AkHotelFilterDataRequestEntity request);
}
