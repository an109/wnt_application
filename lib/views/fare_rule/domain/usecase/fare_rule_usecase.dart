import '../../../../core/error/data_state.dart';
import '../entities/fare_rule_entity.dart';
import '../repository/fare_rule_repository.dart';

class GetFareRulesUsecase {
  final FareRuleRepository repository;

  GetFareRulesUsecase(this.repository);

  Future<DataState<FareRuleResponseEntity>> call(FareRuleRequestEntity params) {
    return repository.getFareRules(params);
  }
}