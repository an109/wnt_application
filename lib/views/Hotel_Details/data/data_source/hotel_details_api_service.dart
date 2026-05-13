import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class HotelDetailsApiService {
  Future<Response> getHotelDetails({
    required String hotelCode,
    required String checkIn,
    required String checkOut,
    String? language,
    String? guestNationality,
  });
}

class HotelDetailsApiServiceImpl implements HotelDetailsApiService {
  final Dio dio;

  HotelDetailsApiServiceImpl(this.dio);

  @override
  Future<Response> getHotelDetails({
    required String hotelCode,
    required String checkIn,
    required String checkOut,
    String? language,
    String? guestNationality,
  }) async {
    try {
      print('CALLING HOTEL DETAILS API: ${Urls.hotelDetails}');
      print('Request Body:');
      print('HotelCode: $hotelCode');
      print('CheckIn: $checkIn');
      print('CheckOut: $checkOut');
      print('Language: ${language ?? "en"}');
      print('GuestNationality: ${guestNationality ?? "IN"}');

      final requestBody = {
        'Hotelcodes': hotelCode,
        'Language': language ?? 'en',
        'CheckIn': checkIn,
        'CheckOut': checkOut,
        'GuestNationality': guestNationality ?? 'IN',
        'PaxRooms': [
          {
            'Adults': 1,
            'Children': 0,
            'ChildrenAges': [],
          }
        ],
      };

      print('Full Request Body: $requestBody');

      final response = await dio.post(
        Urls.hotelDetails,
        data: requestBody,
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Error Type: ${e.type}');
      print('Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.hotelDetails),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}