import '../../../../core/error/data_state.dart';
import '../entity/AKHotelPrice_entity.dart';

abstract class AkHotelPriceRepository {
  Future<DataState<AkHotelPriceEntity>> getPrice(AkHotelPriceRequestEntity request);
}
