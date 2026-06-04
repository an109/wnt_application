import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/upcomingTrip_entity.dart';
import '../../domain/repository/upcomingTrip_repository.dart';
import '../data_source/upcomingTrip_api_service.dart';
import '../models/upcomingTrip_model.dart';

class UpcomingTripRepositoryImpl implements UpcomingTripRepository {
  final UpcomingTripApiService apiService;

  UpcomingTripRepositoryImpl({required this.apiService});

  @override
  Future<DataState<List<UpcomingTripEntity>>> getUpcomingTrips({
    required String userEmail,
  }) async {
    try {
      final response = await apiService.getUpcomingTrips(userEmail: userEmail);

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final bool success = data['success'] as bool? ?? false;

        if (success) {
          final List<dynamic> applicationsJson =
              data['applications'] as List<dynamic>? ?? [];

          final List<UpcomingTripEntity> trips = applicationsJson
              .map((json) => UpcomingTripModel.fromJson(json as Map<String, dynamic>) as UpcomingTripEntity)
              .toList();

          print('Successfully parsed ${trips.length} upcoming trips');
          return DataSuccess<List<UpcomingTripEntity>>(trips);
        } else {
          print('API returned success: false');
          return DataFailed<List<UpcomingTripEntity>>(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'API returned unsuccessful response',
              type: DioExceptionType.badResponse,
              response: response,
            ),
          );
        }
      } else {
        print('Unexpected status code: ${response.statusCode}');
        return DataFailed<List<UpcomingTripEntity>>(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Unexpected status code: ${response.statusCode}',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      print('DioException in repository: ${e.message}');
      return DataFailed<List<UpcomingTripEntity>>(e);
    } catch (e) {
      print('Unknown error in repository: $e');
      return DataFailed<List<UpcomingTripEntity>>(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}