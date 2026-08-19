import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelFilterDataApiService {
  Future<Response> getFilterData(String searchId, String searchTracingKey);
}

class AkHotelFilterDataApiServiceImpl implements AkHotelFilterDataApiService {
  final Dio dio;

  AkHotelFilterDataApiServiceImpl(this.dio);

  @override
  Future<Response> getFilterData(String searchId, String searchTracingKey) async {
    final url = Urls.akHotelFilterData(searchId);
    try {
      // print('CALLING AKBAR HOTEL FILTER DATA API: $url');

      final response = await dio.get(
        url,
        queryParameters: {'search_tracing_key': searchTracingKey},
      );

      print('Filter Data Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Filter Data API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Filter Data Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
