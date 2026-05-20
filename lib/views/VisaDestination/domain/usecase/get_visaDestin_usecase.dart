import '../../../../core/error/data_state.dart';
import '../entity/visaDestin_Entity.dart';
import '../repository/visaDestin_Repository.dart';

class GetVisaDestinationsUseCase {
  final VisaDestinationRepository repository;

  GetVisaDestinationsUseCase(this.repository);

  Future<DataState<List<VisaDestinationEntity>>> call({String domain = 'thewandernova.com'}) {
    return repository.getVisaDestinations(domain: domain);
  }
}