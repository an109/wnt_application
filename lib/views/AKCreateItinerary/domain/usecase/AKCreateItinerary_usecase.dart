import '../../../../core/error/data_state.dart';
import '../entity/AKCreateItinerary_entity.dart';
import '../repository/AKCreateItinerary_repository.dart';

class AkCreateItineraryUseCase {
  final AkCreateItineraryRepository repository;

  AkCreateItineraryUseCase(this.repository);

  Future<DataState<AkCreateItineraryEntity>> call(AkCreateItineraryRequestEntity request) async {
    return await repository.createItinerary(request);
  }
}
