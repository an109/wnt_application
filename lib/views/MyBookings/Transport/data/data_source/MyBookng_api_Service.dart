// import 'package:dio/dio.dart';
// import '../../../../core/constants/urls.dart';
//
// abstract class MyBookingApiService {
//   Future<Response> getBookings(int userId);
// }
//
// class MyBookingApiServiceImpl implements MyBookingApiService {
//   final Dio dio;
//
//   MyBookingApiServiceImpl(this.dio);
//
//   @override
//   Future<Response> getBookings(int userId) async {
//     try {
//       print('CALLING BOOKINGS API: ${Urls.transportBookings} for user_id: $userId');
//
//       final response = await dio.get(
//         Urls.transportBookings,
//         queryParameters: {'user_id': userId},
//       );
//       return response;
//     } on DioException catch (e) {
//       print('API Error: ${e.message}');
//       rethrow;
//     } catch (e) {
//       print('Unknown Error: $e');
//       throw DioException(
//         requestOptions: RequestOptions(path: Urls.transportBookings),
//         error: e.toString(),
//         type: DioExceptionType.unknown,
//       );
//     }
//   }
// }

import 'package:dio/dio.dart';
import '../../../../../core/constants/urls.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/network/dio_client.dart';

abstract class MyBookingApiService {
  Future<Response> getBookings(int userId);
}

class MyBookingApiServiceImpl implements MyBookingApiService {
  final Dio dio;

  //  FIX: Accept Dio instance (should be from DioClient)
  MyBookingApiServiceImpl(this.dio);

  @override
  Future<Response> getBookings(int userId) async {
    try {
      print('🟣 CALLING BOOKINGS API: ${Urls.transportBookings} for user_id: $userId');

      final response = await dio.get(
        Urls.transportBookings,
        queryParameters: {'user_id': userId},
      );

      print('Bookings API response status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print(' Bookings API Error: ${e.message}');
      if (e.response != null) {
        print(' Response status: ${e.response?.statusCode}');
        print(' Response data: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      print(' Unknown Error in bookings API: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.transportBookings),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}