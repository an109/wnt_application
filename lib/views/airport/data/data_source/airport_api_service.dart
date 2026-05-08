import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AirportApiService {
  Future<Response> getAirports({String? country, String? searchQuery});
}

class AirportApiServiceImpl implements AirportApiService {
  final Dio dio;

  AirportApiServiceImpl(this.dio);

  @override
  Future<Response> getAirports({String? country, String? searchQuery}) async {
    try {
      final hasSearchQuery = searchQuery != null && searchQuery.trim().isNotEmpty;

      if (hasSearchQuery) {
        String searchUrl = '${Urls.baseUrl}flights/airports/search/';
        Map<String, dynamic> queryParams = {'q': searchQuery.trim()};

        print('CALLING SEARCH API: $searchUrl?q=${searchQuery.trim()}');

        final response = await dio.get(
          searchUrl,
          queryParameters: queryParams,
        );
        return response;
      }
      else {
        String normalUrl = '${Urls.baseUrl}flights/airports';
        Map<String, dynamic> queryParams = {'limit': '50'};

        if (country != null && country.isNotEmpty) {
          queryParams['country'] = country;
        }

        print('CALLING AIRPORTS API: $normalUrl');
        print('Query params: $queryParams');

        final response = await dio.get(
          normalUrl,
          queryParameters: queryParams,
        );
        return response;
      }
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '${Urls.baseUrl}flights/airports'),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}