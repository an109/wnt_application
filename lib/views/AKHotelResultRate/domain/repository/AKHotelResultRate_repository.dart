import '../../../../core/error/data_state.dart';
import '../entity/AKHotelResultRate_entity.dart';

abstract class AkHotelResultRateRepository {
  Future<DataState<AkHotelResultRateEntity>> getResultRate(AkHotelResultRateRequestEntity request);
}
