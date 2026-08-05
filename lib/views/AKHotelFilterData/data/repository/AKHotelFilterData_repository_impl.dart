import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelFilterData_entity.dart';
import '../../domain/repository/AKHotelFilterData_repository.dart';
import '../data_source/AKHotelFilterData_api_service.dart';
import '../model/AKHotelFilterData_model.dart';

class AkHotelFilterDataRepositoryImpl implements AkHotelFilterDataRepository {
  final AkHotelFilterDataApiService apiService;

  AkHotelFilterDataRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelFilterDataEntity>> getFilterData(AkHotelFilterDataRequestEntity request) async {
    try {
      final response = await apiService.getFilterData(request.searchId, request.searchTracingKey);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelFilterDataModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/result/filterdata/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to fetch filter data',
        ),
      );
    } on DioException catch (e) {
      print('Filter Data Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Filter Data Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/result/filterdata/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
