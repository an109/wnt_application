import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelDetailContentApiService {
  Future<Response> getHotelContent(String searchId, String hotelId, String priceProvider);
}

class AkHotelDetailContentApiServiceImpl implements AkHotelDetailContentApiService {
  final Dio dio;

  AkHotelDetailContentApiServiceImpl(this.dio);

  @override
  Future<Response> getHotelContent(String searchId, String hotelId, String priceProvider) async {
    final url = Urls.akHotelContent(searchId, hotelId);
    try {
      print('CALLING AKBAR HOTEL DETAIL CONTENT API, (priceProvider=$priceProvider)');

      final response = await dio.get(
        url,
        queryParameters: {'priceProvider': priceProvider},
      );

      print('Hotel Detail Content Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Hotel Detail Content API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Hotel Detail Content Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
