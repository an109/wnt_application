import '../../../../core/error/data_state.dart';
import '../entities/trending_routes_entity.dart';

abstract class TrendingRoutesRepository {
  Future<DataState<List<TrendingRouteEntity>>> getTrendingRoutes({String? domain});
}