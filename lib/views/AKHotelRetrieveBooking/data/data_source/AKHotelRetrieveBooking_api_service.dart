import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelRetrieveBookingApiService {
  Future<Response> retrieveBooking(String referenceNumber);
}

class AkHotelRetrieveBookingApiServiceImpl implements AkHotelRetrieveBookingApiService {
  final Dio dio;

  AkHotelRetrieveBookingApiServiceImpl(this.dio);

  @override
  Future<Response> retrieveBooking(String referenceNumber) async {
    try {
      print('CALLING AKBAR HOTEL RETRIEVE BOOKING API: ${Urls.akHotelRetrieveBooking}');

      final response = await dio.post(
        Urls.akHotelRetrieveBooking,
        data: {'ReferenceNumber': referenceNumber},
      );

      print('Retrieve Booking Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Retrieve Booking API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Retrieve Booking Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akHotelRetrieveBooking),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
