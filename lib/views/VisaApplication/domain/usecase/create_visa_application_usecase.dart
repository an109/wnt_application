import '../../../../core/error/data_state.dart';
import '../entity/visaEntity.dart';
import '../repository/visaRepository.dart';

class CreateVisaApplicationUseCase {
  final VisaApplicationRepository repository;

  CreateVisaApplicationUseCase(this.repository);

  Future<DataState<VisaApplicationEntity>> call(
      VisaApplicationEntity application) {
    return repository.createVisaApplication(application);
  }
}