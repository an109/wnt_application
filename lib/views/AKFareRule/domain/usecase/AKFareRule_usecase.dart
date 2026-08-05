import '../../../../core/error/data_state.dart';
import '../entity/AKFareRule_entity.dart';
import '../repository/AKFareRule_repository.dart';

class AkFareRuleUseCase {
  final AkFareRuleRepository repository;

  AkFareRuleUseCase(this.repository);

  Future<DataState<AkFareRuleEntity>> call(AkFareRuleRequestEntity request) async {
    return await repository.getFareRule(request);
  }
}
