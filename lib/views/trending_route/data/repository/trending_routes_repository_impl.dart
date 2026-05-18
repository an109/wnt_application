import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/trending_routes_entity.dart';
import '../../domain/repository/trending_routes_repository.dart';
import '../data_source/trending_route_api_service.dart';
import '../models/trending_routes_model.dart';

class TrendingRoutesRepositoryImpl implements TrendingRoutesRepository {
  final TrendingRoutesApiService apiService;

  TrendingRoutesRepositoryImpl(this.apiService);

  @override
  Future<DataState<List<TrendingRouteEntity>>> getTrendingRoutes({
    String? domain,
  }) async {
    try {
      final response = await apiService.getTrendingRoutes(domain: domain);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final bool success = data['success'] ?? false;

        if (success && data['routes'] != null) {
          final List<dynamic> routesJson = data['routes'];
          final List<TrendingRouteEntity> routes = routesJson
              .map((json) => TrendingRouteModel.fromJson(json))
              .toList();

          print('Successfully fetched ${routes.length} trending routes');
          return DataSuccess(routes);
        } else {
          print('API returned success: false or no routes');
          return  DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'No routes found',
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ),
            ),
          );
        }
      } else {
        print('Unexpected response status: ${response.statusCode}');
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Unexpected response',
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );
      }
    } on DioException catch (e) {
      print('DioException in repository: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Unknown exception in repository: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}