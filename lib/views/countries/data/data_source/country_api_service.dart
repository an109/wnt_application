import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class CountryApiService {
  Future<Response> getCountryList();
}

class CountryApiServiceImpl implements CountryApiService {
  final Dio dio;

  CountryApiServiceImpl(this.dio);

  @override
  Future<Response> getCountryList() async {
    try {
      final String url = '${Urls.baseUrl}flights/countrylist';

      print('CALLING COUNTRY LIST API: $url');

      final response = await dio.get(url);

      print('COUNTRY LIST API Response Status: ${response.statusCode}');

      return response;
    } on DioException catch (e) {
      print('Country List API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error in Country List: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '${Urls.baseUrl}flights/countrylist'),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}