import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKHotelCreateItinerary_model.dart';

abstract class AkHotelCreateItineraryApiService {
  Future<Response> createItinerary(AkHotelCreateItineraryRequestModel request);
}

class AkHotelCreateItineraryApiServiceImpl implements AkHotelCreateItineraryApiService {
  final Dio dio;

  AkHotelCreateItineraryApiServiceImpl(this.dio);

  @override
  Future<Response> createItinerary(AkHotelCreateItineraryRequestModel request) async {
    try {
      print('CALLING AKBAR HOTEL CREATE ITINERARY API: ${Urls.akHotelCreateItinerary}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.akHotelCreateItinerary,
        data: request.toJson(),
      );

      print('Create Itinerary Response Status: ${response.statusCode}');
      print('Create Itinerary Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('Create Itinerary API Error: ${e.message}');
      print('Create Itinerary API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Create Itinerary Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akHotelCreateItinerary),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
