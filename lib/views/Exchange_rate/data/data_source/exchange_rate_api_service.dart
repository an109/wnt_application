import 'package:dio/dio.dart';
import '../../../../../core/constants/urls.dart';

abstract class ExchangeRateApiService {
  Future<Response> fetchExchangeRates({String? apiUrl});
}

class ExchangeRateApiServiceImpl implements ExchangeRateApiService {
  final Dio dio;

  ExchangeRateApiServiceImpl(this.dio);

  @override
  Future<Response> fetchExchangeRates({String? apiUrl}) async {
    try {
      final endpoint = apiUrl ?? Urls.exchangeRatePrimary;

      print('CALLING EXCHANGE RATE API: $endpoint');

      final response = await dio.get(endpoint);

      // Handle both API response formats
      final data = response.data;
      final isSuccess = data['result'] == 'success' || data['status'] == 'success';

      if (!isSuccess) {
        throw DioException(
          requestOptions: RequestOptions(path: endpoint),
          error: 'API returned error: ${data['error-type'] ?? data['error'] ?? 'unknown'}',
          type: DioExceptionType.badResponse,
          response: response,
        );
      }

      print('EXCHANGE RATE API RESPONSE: Success');
      return response;
    } on DioException catch (e) {
      print('EXCHANGE RATE API ERROR: ${e.message}');
      rethrow;
    } catch (e) {
      print('EXCHANGE RATE UNKNOWN ERROR: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.exchangeRatePrimary),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}