import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class HotelBookingApiService {
  Future<Response> getHotelBookingDetails({
    required String bookingCode,
    required String paymentMode,
  });
}

class HotelBookingApiServiceImpl implements HotelBookingApiService {
  final Dio dio;

  HotelBookingApiServiceImpl(this.dio);

  @override
  Future<Response> getHotelBookingDetails({
    required String bookingCode,
    required String paymentMode,
  }) async {
    try {
      print('CALLING HOTEL PREBOOK API: ${Urls.hotelPrebook}');
      print('Request Body: {BookingCode: $bookingCode, PaymentMode: $paymentMode}');

      final response = await dio.post(
        Urls.hotelPrebook,
        data: {
          'BookingCode': bookingCode,
          'PaymentMode': paymentMode,
        },
      );

      print('API Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.hotelPrebook),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}