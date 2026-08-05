import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKFlightInfo_model.dart';

abstract class AkFlightInfoApiService {
  Future<Response> getFlightInfo(AkFlightInfoRequestModel request);
}

class AkFlightInfoApiServiceImpl implements AkFlightInfoApiService {
  final Dio dio;

  AkFlightInfoApiServiceImpl(this.dio);

  @override
  Future<Response> getFlightInfo(AkFlightInfoRequestModel request) async {
    try {
      print('CALLING FLIGHTINFO API: ${Urls.flightInfo}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.flightInfo,
        data: request.toJson(),
      );

      print('FlightInfo Response Status: ${response.statusCode}');
      print('FlightInfo Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('FlightInfo API Error: ${e.message}');
      print('FlightInfo API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('FlightInfo Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.flightInfo),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
