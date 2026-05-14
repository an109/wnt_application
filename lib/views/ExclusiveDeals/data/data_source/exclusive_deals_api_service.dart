import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class ExclusiveDealsApiService {
  Future<Response> getExclusiveDeals({String? domain});
}

class ExclusiveDealsApiServiceImpl implements ExclusiveDealsApiService {
  final Dio dio;

  ExclusiveDealsApiServiceImpl(this.dio);

  @override
  Future<Response> getExclusiveDeals({String? domain}) async {
    try {
      String url = Urls.exclusiveDeals;
      Map<String, dynamic> queryParams = {};

      if (domain != null && domain.trim().isNotEmpty) {
        queryParams['domain'] = domain.trim();
      }

      print('CALLING EXCLUSIVE DEALS API: $url');
      if (queryParams.isNotEmpty) {
        print('Query params: $queryParams');
      }

      final response = await dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.exclusiveDeals),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}