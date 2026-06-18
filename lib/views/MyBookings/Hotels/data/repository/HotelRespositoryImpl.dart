import 'package:dio/dio.dart';

import '../../../../../core/error/data_state.dart';
import '../../../../../core/utils/storage/shared_preference.dart';
import '../../domain/entity/HotelBookingEntity.dart';
import '../../domain/repository/HotelRepository.dart';
import '../data_Source/HotelApiService.dart';
import '../models/HotelBookingModels.dart';


class HotelListRepositoryImpl implements HotelListRepository {
  final HotelListApiService _hotelApiService;
  final PreferencesManager _preferencesManager;

  HotelListRepositoryImpl(this._hotelApiService, this._preferencesManager);

  @override
  Future<DataState<List<HotelBookingListEntity>>> getHotelBookings() async {
    try {
      // Get user_id from shared preferences with type checking
      final dynamic rawUserId = _preferencesManager.getUserId();
      int userId = 0;

      if (rawUserId is int) {
        userId = rawUserId;
      } else if (rawUserId is String) {
        userId = int.tryParse(rawUserId) ?? 0;
      }

      if (userId == 0) {
        print('Repository Error: User ID not found in local storage');
        return DataFailed(DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'User ID not found in local storage',
          type: DioExceptionType.unknown,
        ));
      }

      print('Fetching hotel bookings for user_id: $userId');
      final response = await _hotelApiService.getHotelBookings(userId);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final bool success = responseData['success'] ?? false;

        if (success && responseData['bookings'] != null) {
          final List<dynamic> bookingsJson = responseData['bookings'];
          final List<HotelBookingListModel> bookingModels = bookingsJson
              .map((json) => HotelBookingListModel.fromJson(json as Map<String, dynamic>))
              .toList();

          print('Successfully fetched ${bookingModels.length} hotel bookings');
          return DataSuccess(bookingModels);
        } else {
          return DataFailed(DioException(
            requestOptions: response.requestOptions,
            error: responseData['message'] ?? 'Failed to fetch hotel bookings',
            type: DioExceptionType.badResponse,
          ));
        }
      } else {
        return DataFailed(DioException(
          requestOptions: response.requestOptions,
          error: 'Invalid response from server',
          type: DioExceptionType.badResponse,
        ));
      }
    } on DioException catch (e) {
      print('Repository DioException: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Repository Unknown Error: $e');
      return DataFailed(DioException(
        requestOptions: RequestOptions(path: ''),
        error: e.toString(),
        type: DioExceptionType.unknown,
      ));
    }
  }
}