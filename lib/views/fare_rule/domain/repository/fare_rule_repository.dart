import '../../../../core/error/data_state.dart';
import '../entities/fare_rule_entity.dart';

abstract class FareRuleRepository {
  Future<DataState<FareRuleResponseEntity>> getFareRules(FareRuleRequestEntity request);
}