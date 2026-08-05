import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKCreateItinerary_model.dart';

abstract class AkCreateItineraryApiService {
  Future<Response> createItinerary(AkCreateItineraryRequestModel request);
}

class AkCreateItineraryApiServiceImpl implements AkCreateItineraryApiService {
  final Dio dio;

  AkCreateItineraryApiServiceImpl(this.dio);

  @override
  Future<Response> createItinerary(AkCreateItineraryRequestModel request) async {
    try {
      print('CALLING CREATEITINERARY API: ${Urls.createItinerary}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.createItinerary,
        data: request.toJson(),
      );

      print('CreateItinerary Response Status: ${response.statusCode}');
      print('CreateItinerary Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('CreateItinerary API Error: ${e.message}');
      print('CreateItinerary API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('CreateItinerary Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.createItinerary),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
