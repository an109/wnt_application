import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class TransportResultApiService {
  Future<Response> getTransportResult({
    required String searchId,
    required String resultId,
  });
}

class TransportResultApiServiceImpl implements TransportResultApiService {
  final Dio dio;

  TransportResultApiServiceImpl(this.dio);

  @override
  Future<Response> getTransportResult({
    required String searchId,
    required String resultId,
  }) async {
    try {
      final url = Urls.transportSearchResult(searchId, resultId);

      print('CALLING TRANSPORT RESULT API: $url');

      final response = await dio.get(url);

      print('TRANSPORT RESULT API RESPONSE STATUS: ${response.statusCode}');

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('API Error Type: ${e.type}');
      print('API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(
          path: Urls.transportSearchResult(searchId, resultId),
        ),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}