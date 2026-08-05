import '../../../../core/error/data_state.dart';
import '../entity/AKFareRule_entity.dart';

abstract class AkFareRuleRepository {
  Future<DataState<AkFareRuleEntity>> getFareRule(AkFareRuleRequestEntity request);
}
