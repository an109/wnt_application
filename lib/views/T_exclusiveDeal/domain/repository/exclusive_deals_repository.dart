import '../../../../core/error/data_state.dart';
import '../entities/exclusive_deal_entity.dart';

abstract class ExclusiveDealsRepository {
  Future<DataState<List<ExclusiveDealEntity>>> getExclusiveDeals({String? domain});
}