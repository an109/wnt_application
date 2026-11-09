import 'package:dio/dio.dart';

import '../../../../../core/error/data_state.dart';
import '../../../../../core/utils/storage/shared_preference.dart';
import '../../domain/entity/InsuranceBookingEntity.dart';
import '../../domain/repository/InsuranceBookingRepository.dart';
import '../data_source/InsuranceBookingApiService.dart';
import '../models/InsuranceBookingModel.dart';

class InsuranceBookingRepositoryImpl implements InsuranceBookingRepository {
  final InsuranceBookingApiService _apiService;
  final PreferencesManager _preferencesManager;

  InsuranceBookingRepositoryImpl(this._apiService, this._preferencesManager);

  @override
  Future<DataState<List<InsuranceBookingEntity>>> getInsuranceBookings() async {
    try {
      final dynamic rawUserId = _preferencesManager.getUserId();
      int userId = 0;

      if (rawUserId is int) {
        userId = rawUserId;
      } else if (rawUserId is String) {
        userId = int.tryParse(rawUserId) ?? 0;
      }

      if (userId == 0) {
        return DataFailed(DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'User ID not found',
          type: DioExceptionType.unknown,
        ));
      }

      final response = await _apiService.getInsuranceBookings(userId);

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> bookingsJson;

        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          bookingsJson = (responseData['bookings'] ?? responseData['results'] ?? responseData['data'] ?? []) as List<dynamic>;
        } else if (response.data is List) {
          bookingsJson = response.data as List<dynamic>;
        } else {
          bookingsJson = [];
        }

        final bookings = bookingsJson
            .map((json) => InsuranceBookingModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return DataSuccess(bookings);
      } else {
        return DataFailed(DioException(
          requestOptions: response.requestOptions,
          error: 'Invalid response from server',
          type: DioExceptionType.badResponse,
        ));
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(DioException(
        requestOptions: RequestOptions(path: ''),
        error: e.toString(),
        type: DioExceptionType.unknown,
      ));
    }
  }
}
