import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelRoomsApiService {
  Future<Response> getRooms(String searchId, String hotelId, String searchTracingKey);
}

class AkHotelRoomsApiServiceImpl implements AkHotelRoomsApiService {
  final Dio dio;

  AkHotelRoomsApiServiceImpl(this.dio);

  @override
  Future<Response> getRooms(String searchId, String hotelId, String searchTracingKey) async {
    final url = Urls.akHotelRooms(searchId, hotelId);
    try {
      // print('CALLING AKBAR HOTEL ROOMS API: $url');

      final response = await dio.get(
        url,
        queryParameters: {'search_tracing_key': searchTracingKey},
      );

      print('Rooms Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Rooms API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Rooms Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
