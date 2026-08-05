import '../../../../core/error/data_state.dart';
import '../entity/AKCreateItinerary_entity.dart';

abstract class AkCreateItineraryRepository {
  Future<DataState<AkCreateItineraryEntity>> createItinerary(
      AkCreateItineraryRequestEntity request);
}
