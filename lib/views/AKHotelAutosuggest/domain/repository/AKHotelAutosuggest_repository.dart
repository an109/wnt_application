import '../../../../core/error/data_state.dart';
import '../entity/AKHotelAutosuggest_entity.dart';

abstract class AkHotelAutosuggestRepository {
  Future<DataState<AkHotelAutosuggestEntity>> autosuggest(AkHotelAutosuggestRequestEntity request);
}
