import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/akflight_Search_model.dart';

abstract class AkFlightSearchApiService {
  Future<AkFlightSearchModel> searchFlights(FlightSearchRequestModel request);
}

class AkFlightSearchApiServiceImpl implements AkFlightSearchApiService {
  final Dio dio;

  AkFlightSearchApiServiceImpl(this.dio);

  @override
  Future<AkFlightSearchModel> searchFlights(FlightSearchRequestModel request) async {
    try {
      print('CALLING FLIGHT SEARCH API: ${Urls.flightSearch}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.flightSearch,
        data: request.toJson(),
      );

      print('Flight Search Response: ${response.data}');

      if (response.statusCode == 200) {
        return AkFlightSearchModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('Flight Search API Error: ${e.message}');
      print('Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Flight Search Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.flightSearch),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}