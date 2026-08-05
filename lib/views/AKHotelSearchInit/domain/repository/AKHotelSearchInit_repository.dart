import '../../../../core/error/data_state.dart';
import '../entity/AKHotelSearchInit_entity.dart';

abstract class AkHotelSearchInitRepository {
  Future<DataState<AkHotelSearchInitEntity>> searchInit(AkHotelSearchInitRequestEntity request);
}
