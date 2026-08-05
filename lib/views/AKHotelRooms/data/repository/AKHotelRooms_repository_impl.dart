import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelRooms_entity.dart';
import '../../domain/repository/AKHotelRooms_repository.dart';
import '../data_source/AKHotelRooms_api_service.dart';
import '../model/AKHotelRooms_model.dart';

class AkHotelRoomsRepositoryImpl implements AkHotelRoomsRepository {
  final AkHotelRoomsApiService apiService;

  AkHotelRoomsRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelRoomsResultEntity>> getRooms(AkHotelRoomsRequestEntity request) async {
    try {
      final response = await apiService.getRooms(request.searchId, request.hotelId, request.searchTracingKey);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelRoomsResultModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/result/rooms/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to fetch rooms',
          message: 'Failed to fetch rooms',
        ),
      );
    } on DioException catch (e) {
      print('Rooms Repository Error: ${e.message}');
      // A 502 here is usually Akbar's own "No rooms found" for this
      // hotel/dates (real unavailability, not a transport failure) —
      // {"success": false, "error": "..."} carries the real reason, so
      // surface that instead of Dio's generic bad-response wording.
      final responseData = e.response?.data;
      if (responseData is Map && responseData['error'] != null) {
        final message = responseData['error'].toString();
        return DataFailed(e.copyWith(error: message, message: message));
      }
      return DataFailed(e);
    } catch (e) {
      print('Rooms Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/result/rooms/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
