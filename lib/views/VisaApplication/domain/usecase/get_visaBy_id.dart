// lib/features/visa_applications/domain/usecases/get_visa_application_by_id_usecase.dart
import '../../../../core/error/data_state.dart';
import '../entity/visaEntity.dart';
import '../repository/visaRepository.dart';

class GetVisaApplicationByIdUseCase {
  final VisaApplicationRepository repository;

  GetVisaApplicationByIdUseCase(this.repository);

  Future<DataState<VisaApplicationEntity>> call(int id) {
    return repository.getVisaApplicationById(id);
  }
}