import '../../../../core/error/data_state.dart';
import '../entity/AKHotelResultContent_entity.dart';

abstract class AkHotelResultContentRepository {
  Future<DataState<AkHotelResultContentEntity>> getResultContent(AkHotelResultContentRequestEntity request);
}
