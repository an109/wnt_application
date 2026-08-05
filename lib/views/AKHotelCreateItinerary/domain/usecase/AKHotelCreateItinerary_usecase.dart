import '../../../../core/error/data_state.dart';
import '../entity/AKHotelCreateItinerary_entity.dart';
import '../repository/AKHotelCreateItinerary_repository.dart';

class AkHotelCreateItineraryUseCase {
  final AkHotelCreateItineraryRepository repository;

  AkHotelCreateItineraryUseCase(this.repository);

  Future<DataState<AkHotelCreateItineraryEntity>> call(AkHotelCreateItineraryRequestEntity request) async {
    return await repository.createItinerary(request);
  }
}
