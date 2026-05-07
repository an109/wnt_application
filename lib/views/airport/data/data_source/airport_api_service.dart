import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AirportApiService {
  Future<Response> getAirports({String? country});
}

class AirportApiServiceImpl implements AirportApiService {
  final Dio dio;

  AirportApiServiceImpl(this.dio);

  @override
  Future<Response> getAirports({String? country}) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (country != null && country.isNotEmpty) {
        queryParams['country'] = country;
      }

      // Make GET request
      final response = await dio.get(
        Urls.airports,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return response;
    } on DioException catch (e) {
      // Re-throw to be handled by repository
      rethrow;
    } catch (e) {
      // Wrap unknown errors in DioException
      throw DioException(
        requestOptions: RequestOptions(path: Urls.airports),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}