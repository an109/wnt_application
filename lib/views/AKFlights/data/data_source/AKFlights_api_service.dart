import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkflightsApiService {
  Future<Response> getExpSearch({required String tui});
}

class AkflightsApiServiceImpl implements AkflightsApiService {
  final Dio dio;

  AkflightsApiServiceImpl(this.dio);

  @override
  Future<Response> getExpSearch({required String tui}) async {
    try {
      print('CALLING GETEXPSEARCH API: ${Urls.getExpSearch}');
      print('Request Body: {"tui": "$tui"}');

      final response = await dio.post(
        Urls.getExpSearch,
        data: {'tui': tui},
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('API Error Type: ${e.type}');
      print('API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.getExpSearch),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}