import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/network/dio_client.dart';
import '../model/flight_search_request_model.dart';
import '../model/flight_search_response_model.dart';

class FlightApiService {
  final DioClient _dioClient;

  FlightApiService(this._dioClient);

  Future<FlightSearchResponseModel> searchFlights(
      FlightSearchRequestModel request) async {
    try {
      final response = await _dioClient.instance.post(
        Urls.flightSearch,
        data: request.toJson(),
      );

      return FlightSearchResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw e;
    }
  }
}