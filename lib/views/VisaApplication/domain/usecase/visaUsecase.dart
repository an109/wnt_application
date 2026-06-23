import '../../../../core/error/data_state.dart';
import '../entity/visaEntity.dart';
import '../repository/visaRepository.dart';

class GetVisaApplicationsUseCase {
  final VisaApplicationRepository repository;

  GetVisaApplicationsUseCase(this.repository);

  Future<DataState<List<VisaApplicationEntity>>> call() {
    return repository.getAllVisaApplications();
  }
}