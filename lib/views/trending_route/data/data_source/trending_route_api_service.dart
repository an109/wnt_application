import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class TrendingRoutesApiService {
  Future<Response> getTrendingRoutes({String? domain});
}

class TrendingRoutesApiServiceImpl implements TrendingRoutesApiService {
  final Dio dio;

  TrendingRoutesApiServiceImpl(this.dio);

  @override
  Future<Response> getTrendingRoutes({String? domain}) async {
    try {
      String url = Urls.trendingRoutes;
      Map<String, dynamic> queryParams = {};

      if (domain != null && domain.isNotEmpty) {
        queryParams['domain'] = domain;
      }

      print('CALLING TRENDING ROUTES API: $url');
      print('Query params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('TRENDING ROUTES API RESPONSE STATUS: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('API Error Type: ${e.type}');
      print('API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.trendingRoutes),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}