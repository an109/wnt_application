import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKRetrieveBooking_model.dart';

abstract class AkRetrieveBookingApiService {
  Future<Response> retrieveBooking(AkRetrieveBookingRequestModel request);
}

class AkRetrieveBookingApiServiceImpl implements AkRetrieveBookingApiService {
  final Dio dio;

  AkRetrieveBookingApiServiceImpl(this.dio);

  @override
  Future<Response> retrieveBooking(AkRetrieveBookingRequestModel request) async {
    try {
      print('CALLING RETRIEVEBOOKING API: ${Urls.retrieveBooking}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.retrieveBooking,
        data: request.toJson(),
      );

      print('RetrieveBooking Response Status: ${response.statusCode}');
      print('RetrieveBooking Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('RetrieveBooking API Error: ${e.message}');
      print('RetrieveBooking API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('RetrieveBooking Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.retrieveBooking),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
