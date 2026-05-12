import '../../../../core/error/data_state.dart';
import '../../data/models/destination_model.dart';

abstract class DestinationRepository {
  Future<DataState<DestinationSearchModel>> searchDestinations({
    required String query,
    String? countryCode,
    int limit = 100,
  });
}