import 'package:dio/dio.dart';
import '../../../../../core/constants/urls.dart';

abstract class HotelListApiService {
  Future<Response> getHotelBookings(int userId);
}

class HotelListApiServiceImpl implements HotelListApiService {
  final Dio dio;

  HotelListApiServiceImpl(this.dio);

  @override
  Future<Response> getHotelBookings(int userId) async {
    try {
      print('CALLING HOTEL BOOKINGS API: ${Urls.hotelBookingsList} for user_id: $userId');

      final response = await dio.get(
        Urls.hotelBookingsList,
        queryParameters: {'user_id': userId},
      );

      print('Hotel Bookings API response status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Hotel Bookings API Error: ${e.message}');
      if (e.response != null) {
        print('Response status: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      print('Unknown Error in Hotel Bookings API: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.hotelBookingsList),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}