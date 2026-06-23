import '../../../../core/error/data_state.dart';
import '../entity/visaEntity.dart';

abstract class VisaApplicationRepository {
  Future<DataState<List<
      VisaApplicationEntity>>> getAllVisaApplications();
  Future<DataState<VisaApplicationEntity>> getVisaApplicationById(int id);
  Future<DataState<VisaApplicationEntity>> createVisaApplication(
      VisaApplicationEntity application);
}