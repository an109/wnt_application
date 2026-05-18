import '../../../../core/error/data_state.dart';
import '../entities/trending_routes_entity.dart';
import '../repository/trending_routes_repository.dart';

class GetTrendingRoutesUseCase {
  final TrendingRoutesRepository repository;

  GetTrendingRoutesUseCase(this.repository);

  Future<DataState<List<TrendingRouteEntity>>> call({String? domain}) async {
    print('Executing GetTrendingRoutesUseCase with domain: $domain');
    return await repository.getTrendingRoutes(domain: domain);
  }
}