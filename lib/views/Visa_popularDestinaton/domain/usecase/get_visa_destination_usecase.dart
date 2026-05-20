import '../../../../core/error/data_state.dart';
import '../entities/visa_destination_entity.dart';
import '../repository/visa_destination_repository.dart';

class GetVisaPopularDestinationsUsecase {
  final VisaPopularDestinationRepository repository;

  GetVisaPopularDestinationsUsecase(this.repository);

  Future<DataState<List<VisaPopularDestinationEntity>>> call({String? domain}) {
    print('Executing GetVisaPopularDestinationsUsecase with domain: $domain');
    return repository.getVisaDestinations(domain: domain);
  }
}