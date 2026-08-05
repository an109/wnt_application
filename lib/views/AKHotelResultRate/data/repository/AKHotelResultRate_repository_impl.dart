import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelResultRate_entity.dart';
import '../../domain/repository/AKHotelResultRate_repository.dart';
import '../data_source/AKHotelResultRate_api_service.dart';
import '../model/AKHotelResultRate_model.dart';

class AkHotelResultRateRepositoryImpl implements AkHotelResultRateRepository {
  final AkHotelResultRateApiService apiService;

  AkHotelResultRateRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelResultRateEntity>> getResultRate(AkHotelResultRateRequestEntity request) async {
    try {
      final response = await apiService.getResultRate(request.searchId, request.searchTracingKey);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelResultRateModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/result/rate/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to fetch hotel rates',
        ),
      );
    } on DioException catch (e) {
      print('Result Rate Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Result Rate Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/result/rate/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
