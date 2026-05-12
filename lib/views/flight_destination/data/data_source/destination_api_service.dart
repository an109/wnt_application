import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class DestinationApiService {
  Future<Response> searchDestinations({
    required String query,
    String? countryCode,
    int limit = 100,
  });
}

class DestinationApiServiceImpl implements DestinationApiService {
  final Dio dio;

  DestinationApiServiceImpl(this.dio);

  @override
  Future<Response> searchDestinations({
    required String query,
    String? countryCode,
    int limit = 100,
  }) async {
    try {
      String url = '${Urls.baseUrl}tbo-hotel/destination-search/';
      Map<String, dynamic> queryParams = {
        'q': query.trim(),
        'limit': limit.toString(),
      };

      if (countryCode != null && countryCode.isNotEmpty) {
        queryParams['countryCode'] = countryCode;
      }

      print('CALLING DESTINATION SEARCH API: $url');
      print('Query params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );

      print('API Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(
          path: '${Urls.baseUrl}tbo-hotel/destination-search/',
        ),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}