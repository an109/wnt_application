import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelPriceApiService {
  Future<Response> getPrice(String searchId, String hotelId, String priceProvider, String recommendationId, String searchTracingKey);
}

class AkHotelPriceApiServiceImpl implements AkHotelPriceApiService {
  final Dio dio;

  AkHotelPriceApiServiceImpl(this.dio);

  @override
  Future<Response> getPrice(
    String searchId,
    String hotelId,
    String priceProvider,
    String recommendationId,
    String searchTracingKey,
  ) async {
    final url = Urls.akHotelPrice(searchId, hotelId, priceProvider, recommendationId);
    try {
      print('CALLING AKBAR HOTEL PRICE API: $url');

      final response = await dio.get(
        url,
        queryParameters: {'search_tracing_key': searchTracingKey},
      );

      print('Price Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Price API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Price Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
