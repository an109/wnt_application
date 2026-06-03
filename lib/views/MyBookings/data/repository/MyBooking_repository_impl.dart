import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../domain/entity/MyBooking_entity.dart';
import '../../domain/repository/MyBooking_repository.dart';
import '../data_source/MyBookng_api_Service.dart';
import '../models/MyBooking_model.dart';


class MyBookingRepositoryImpl implements MyBookingRepository {
  final MyBookingApiService _bookingApiService;
  final PreferencesManager _preferencesManager;

  MyBookingRepositoryImpl(this._bookingApiService, this._preferencesManager);

  @override
  Future<DataState<List<BookingEntity>>> getBookings() async {
    try {
      // Get user_id from shared preferences
      // Note: Adjust 'getUserId()' based on your actual PreferencesManager method name
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

      print('Fetching bookings for user_id: $userId');
      final response = await _bookingApiService.getBookings(userId);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final bool success = responseData['success'] ?? false;

        if (success && responseData['bookings'] != null) {
          final List<dynamic> bookingsJson = responseData['bookings'];
          final List<BookingModel> bookingModels = bookingsJson
              .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
              .toList();

          print('Successfully fetched ${bookingModels.length} bookings');
          return DataSuccess(bookingModels);
        } else {
          return DataFailed(DioException(
            requestOptions: response.requestOptions,
            error: responseData['message'] ?? 'Failed to fetch bookings',
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