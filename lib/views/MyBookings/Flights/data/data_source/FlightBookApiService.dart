import 'package:dio/dio.dart';

import '../../../../../core/constants/urls.dart';

abstract class FlightBookApiService {
  Future<Response> getBookings({int? userId});
}

class FlightBookApiServiceImpl implements FlightBookApiService {
  final Dio dio;

  FlightBookApiServiceImpl(this.dio);

  @override
  Future<Response> getBookings({int? userId}) async {
    try {
      String url = Urls.bookings;
      Map<String, dynamic> queryParams = {};

      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      print('CALLING BOOKINGS API: $url');
      print('Query params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('BOOKINGS API RESPONSE STATUS: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.bookings),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}