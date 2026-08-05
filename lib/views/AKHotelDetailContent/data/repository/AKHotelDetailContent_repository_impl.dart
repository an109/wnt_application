import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelDetailContent_entity.dart';
import '../../domain/repository/AKHotelDetailContent_repository.dart';
import '../data_source/AKHotelDetailContent_api_service.dart';
import '../model/AKHotelDetailContent_model.dart';

class AkHotelDetailContentRepositoryImpl implements AkHotelDetailContentRepository {
  final AkHotelDetailContentApiService apiService;

  AkHotelDetailContentRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelDetailContentEntity>> getHotelContent(AkHotelDetailContentRequestEntity request) async {
    try {
      final response = await apiService.getHotelContent(request.searchId, request.hotelId, request.priceProvider);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelDetailContentModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/hotels/content/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to fetch hotel content',
        ),
      );
    } on DioException catch (e) {
      print('Hotel Detail Content Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Hotel Detail Content Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/hotels/content/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
