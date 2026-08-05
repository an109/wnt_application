import '../../../../core/error/data_state.dart';
import '../entity/AKHotelCreateItinerary_entity.dart';

abstract class AkHotelCreateItineraryRepository {
  Future<DataState<AkHotelCreateItineraryEntity>> createItinerary(AkHotelCreateItineraryRequestEntity request);
}
