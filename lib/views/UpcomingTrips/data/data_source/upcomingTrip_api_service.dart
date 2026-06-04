// lib/features/upcoming_trips/data/data_source/upcoming_trip_api_service.dart

import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class UpcomingTripApiService {
  Future<Response> getUpcomingTrips({required String userEmail});
}

class UpcomingTripApiServiceImpl implements UpcomingTripApiService {
  final Dio dio;

  UpcomingTripApiServiceImpl(this.dio);

  @override
  Future<Response> getUpcomingTrips({required String userEmail}) async {
    try {
      final String url = Urls.visaApplications;
      final Map<String, dynamic> queryParams = {
        'user_email': userEmail,
      };

      print('CALLING UPCOMING TRIPS API: $url');
      print('Query params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );

      print('RESPONSE STATUS: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.visaApplications),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}