import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class TravelStoriesApiService {
  Future<Response> getTravelStories({
    String? status,
    String? domain,
    int? limit,
  });

  Future<Response> getTravelStoryBySlug(String slug);
}

class TravelStoriesApiServiceImpl implements TravelStoriesApiService {
  final Dio dio;

  TravelStoriesApiServiceImpl(this.dio);

  @override
  Future<Response> getTravelStories({
    String? status,
    String? domain,
    int? limit,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (domain != null && domain.isNotEmpty) {
        queryParams['domain'] = domain;
      }

      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      print('CALLING TRAVEL STORIES API: ${Urls.travelStories}');
      print('Query params: $queryParams');

      final response = await dio.get(
        Urls.travelStories,
        queryParameters: queryParams,
      );

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.travelStories),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> getTravelStoryBySlug(String slug) async {
    try {
      print('CALLING TRAVEL STORY BY SLUG API: ${Urls.travelStories}$slug/');

      final response = await dio.get(
        '${Urls.travelStories}$slug/',
      );

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '${Urls.travelStories}$slug/'),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}