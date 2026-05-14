import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class TpollSearchApiService {
  Future<Response> pollSearchResults(String searchId);
}

class TpollSearchApiServiceImpl implements TpollSearchApiService {
  final Dio dio;

  TpollSearchApiServiceImpl(this.dio);

  @override
  Future<Response> pollSearchResults(String searchId) async {
    try {
      final url = Urls.tpollSearch(searchId);
      print('CALLING TPOLL SEARCH API: $url');

      final response = await dio.get(url);
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.tpollSearch(searchId)),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}