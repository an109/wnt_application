import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelResultContent_entity.dart';
import '../../domain/repository/AKHotelResultContent_repository.dart';
import '../data_source/AKHotelResultContent_api_service.dart';
import '../model/AKHotelResultContent_model.dart';

class AkHotelResultContentRepositoryImpl implements AkHotelResultContentRepository {
  final AkHotelResultContentApiService apiService;

  AkHotelResultContentRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelResultContentEntity>> getResultContent(AkHotelResultContentRequestEntity request) async {
    try {
      final response = await apiService.getResultContent(
        request.searchId,
        request.searchTracingKey,
        request.limit,
        request.offset,
      );
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelResultContentModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/result/content/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to fetch hotel content',
        ),
      );
    } on DioException catch (e) {
      print('Result Content Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Result Content Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/result/content/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
