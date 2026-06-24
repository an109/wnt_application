import '../../../../../core/error/data_state.dart';
import '../../../../VisaApplication/domain/entity/visaEntity.dart';

abstract class VRepository {
  Future<DataState<List<VisaApplicationEntity>>> getVisaApplications({String? userEmail});
}