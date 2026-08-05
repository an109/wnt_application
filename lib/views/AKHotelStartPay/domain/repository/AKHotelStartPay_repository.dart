import '../../../../core/error/data_state.dart';
import '../entity/AKHotelStartPay_entity.dart';

abstract class AkHotelStartPayRepository {
  Future<DataState<AkHotelStartPayEntity>> startPay(AkHotelStartPayRequestEntity request);
}
