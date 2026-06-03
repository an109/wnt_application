import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class MyBookingApiService {
  Future<Response> getBookings(int userId);
}

class MyBookingApiServiceImpl implements MyBookingApiService {
  final Dio dio;

  MyBookingApiServiceImpl(this.dio);

  @override
  Future<Response> getBookings(int userId) async {
    try {
      print('CALLING BOOKINGS API: ${Urls.transportBookings} for user_id: $userId');

      final response = await dio.get(
        Urls.transportBookings,
        queryParameters: {'user_id': userId},
      );
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.transportBookings),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}