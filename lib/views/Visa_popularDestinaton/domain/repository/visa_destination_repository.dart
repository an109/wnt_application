import '../../../../core/error/data_state.dart';
import '../entities/visa_destination_entity.dart';

abstract class VisaPopularDestinationRepository {
  Future<DataState<List<VisaPopularDestinationEntity>>> getVisaDestinations({String? domain});
}