import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelPrice_entity.dart';
import '../../domain/repository/AKHotelPrice_repository.dart';
import '../data_source/AKHotelPrice_api_service.dart';
import '../model/AKHotelPrice_model.dart';

class AkHotelPriceRepositoryImpl implements AkHotelPriceRepository {
  final AkHotelPriceApiService apiService;

  AkHotelPriceRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelPriceEntity>> getPrice(AkHotelPriceRequestEntity request) async {
    try {
      final response = await apiService.getPrice(
        request.searchId,
        request.hotelId,
        request.priceProvider,
        request.recommendationId,
        request.searchTracingKey,
      );
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelPriceModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/price/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to confirm price',
        ),
      );
    } on DioException catch (e) {
      print('Price Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Price Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/price/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
