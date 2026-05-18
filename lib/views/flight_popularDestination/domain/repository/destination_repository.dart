import '../../../../core/error/data_state.dart';
import '../entities/Popular_destination_entity.dart';

abstract class PopularDestinationRepository {
  Future<DataState<List<DestinationEntity>>> getPopularDestinations();
}