import '../../../../core/error/data_state.dart';
import '../entities/exclusive_deal_entity.dart';
import '../repository/exclusive_deals_repository.dart';

class GetExclusiveDealsUseCase {
  final ExclusiveDealsRepository repository;

  GetExclusiveDealsUseCase(this.repository);

  Future<DataState<List<ExclusiveDealEntity>>> call({String? domain}) async {
    return await repository.getExclusiveDeals(domain: domain);
  }
}