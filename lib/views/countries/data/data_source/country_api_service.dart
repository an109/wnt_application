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
      final response = await dio.get(Urls.hotelCachedCountries);
      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: Urls.hotelCachedCountries),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}