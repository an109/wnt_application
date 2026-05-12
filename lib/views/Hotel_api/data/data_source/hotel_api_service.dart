import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class HotelApiService {
  Future<Response> getHotelsByCity({
    required String cityCode,
    required String checkIn,
    required String checkOut,
    required String guestNationality,
    required int page,
    required int pageSize,
    Map<String, dynamic>? filters,
    List<Map<String, dynamic>>? paxRooms,
  });
}

class HotelApiServiceImpl implements HotelApiService {
  final Dio dio;

  HotelApiServiceImpl(this.dio);

  @override
  Future<Response> getHotelsByCity({
    required String cityCode,
    required String checkIn,
    required String checkOut,
    required String guestNationality,
    required int page,
    required int pageSize,
    Map<String, dynamic>? filters,
    List<Map<String, dynamic>>? paxRooms,
  }) async {
    try {
      final requestBody = {
        'CityCode': cityCode,
        'CheckIn': checkIn,
        'CheckOut': checkOut,
        'GuestNationality': guestNationality,
        'IsDetailedResponse': true,
        'Filters': filters ?? {
          'Refundable': false,
          'NoofRooms': 0,
          'MealType': 'All',
        },
        'PaxRooms': paxRooms ?? [
          {
            'Adults': 2,
            'Children': 0,
            'ChildrenAges': [],
          }
        ],
        'ResponseTime': 15,
        'page': page,
        'page_size': pageSize,
      };

      print('CALLING HOTELS API: ${Urls.hotelsByCity}');
      print('Request Body: $requestBody');

      final response = await dio.post(
        Urls.hotelsByCity,
        data: requestBody,
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
        requestOptions: RequestOptions(path: Urls.hotelsByCity),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}