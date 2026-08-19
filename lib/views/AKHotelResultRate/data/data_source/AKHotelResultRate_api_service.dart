import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelResultRateApiService {
  Future<Response> getResultRate(String searchId, String searchTracingKey);
}

class AkHotelResultRateApiServiceImpl implements AkHotelResultRateApiService {
  final Dio dio;

  AkHotelResultRateApiServiceImpl(this.dio);

  @override
  Future<Response> getResultRate(String searchId, String searchTracingKey) async {
    final url = Urls.akHotelResultRate(searchId);
    try {
      print('CALLING AKBAR HOTEL RESULT RATE API:');

      final response = await dio.get(
        url,
        queryParameters: {'search_tracing_key': searchTracingKey},
      );

      print('Result Rate Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Result Rate API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Result Rate Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
