import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelAutosuggest_entity.dart';
import '../../domain/repository/AKHotelAutosuggest_repository.dart';
import '../data_source/AKHotelAutosuggest_api_service.dart';
import '../model/AKHotelAutosuggest_model.dart';

class AkHotelAutosuggestRepositoryImpl implements AkHotelAutosuggestRepository {
  final AkHotelAutosuggestApiService apiService;

  AkHotelAutosuggestRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelAutosuggestEntity>> autosuggest(AkHotelAutosuggestRequestEntity request) async {
    try {
      final response = await apiService.autosuggest(request.term);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelAutosuggestModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/autosuggest/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to fetch location suggestions',
        ),
      );
    } on DioException catch (e) {
      print('Autosuggest Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Autosuggest Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/autosuggest/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
