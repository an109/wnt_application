import '../../../../core/error/data_state.dart';
import '../entity/AKHotelDetailContent_entity.dart';

abstract class AkHotelDetailContentRepository {
  Future<DataState<AkHotelDetailContentEntity>> getHotelContent(AkHotelDetailContentRequestEntity request);
}
