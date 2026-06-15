import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class TransactionApiService {
  Future<Response> getTransactions({
    String? type,
    int? days,
    String? search,
    int page,
    int pageSize,
  });
}

class TransactionApiServiceImpl implements TransactionApiService {
  final Dio dio;

  TransactionApiServiceImpl(this.dio);

  @override
  Future<Response> getTransactions({
    String? type,
    int? days,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      String url = Urls.walletTransactions;
      Map<String, dynamic> queryParams = {
        'page': page,
        'page_size': pageSize,
      };

      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (days != null) queryParams['days'] = days;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      print('CALLING TRANSACTIONS API: $url');
      print('Query params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.walletTransactions),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}