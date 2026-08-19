import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelResultContentApiService {
  Future<Response> getResultContent(String searchId, String searchTracingKey, int limit, int offset);
}

class AkHotelResultContentApiServiceImpl implements AkHotelResultContentApiService {
  final Dio dio;

  AkHotelResultContentApiServiceImpl(this.dio);

  @override
  Future<Response> getResultContent(String searchId, String searchTracingKey, int limit, int offset) async {
    final url = Urls.akHotelResultContent(searchId);
    try {
      print('CALLING AKBAR HOTEL RESULT CONTENT API, (limit=$limit offset=$offset)');

      final response = await dio.get(
        url,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          'search_tracing_key': searchTracingKey,
        },
      );

      print('Result Content Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Result Content API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Result Content Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
