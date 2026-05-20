import '../../../../core/error/data_state.dart';
import '../entity/visaDestin_Entity.dart';

abstract class VisaDestinationRepository {
  Future<DataState<List<VisaDestinationEntity>>> getVisaDestinations({String domain});
}