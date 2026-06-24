import '../../../../../core/error/data_state.dart';
import '../../../../VisaApplication/domain/entity/visaEntity.dart';
import '../repository/VRepository.dart';

class GetVApplicationsUseCase {
  final VRepository repository;

  GetVApplicationsUseCase(this.repository);

  Future<DataState<List<VisaApplicationEntity>>> call({String? userEmail}) async {
    return await repository.getVisaApplications(userEmail: userEmail);
  }
}