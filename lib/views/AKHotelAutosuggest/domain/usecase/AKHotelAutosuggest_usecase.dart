import '../../../../core/error/data_state.dart';
import '../entity/AKHotelAutosuggest_entity.dart';
import '../repository/AKHotelAutosuggest_repository.dart';

class AkHotelAutosuggestUseCase {
  final AkHotelAutosuggestRepository repository;

  AkHotelAutosuggestUseCase(this.repository);

  Future<DataState<AkHotelAutosuggestEntity>> call(AkHotelAutosuggestRequestEntity request) async {
    return await repository.autosuggest(request);
  }
}
