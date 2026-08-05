import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelSearchInit_entity.dart';
import '../../domain/repository/AKHotelSearchInit_repository.dart';
import '../data_source/AKHotelSearchInit_api_service.dart';
import '../model/AKHotelSearchInit_model.dart';

class AkHotelSearchInitRepositoryImpl implements AkHotelSearchInitRepository {
  final AkHotelSearchInitApiService apiService;

  AkHotelSearchInitRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelSearchInitEntity>> searchInit(AkHotelSearchInitRequestEntity request) async {
    try {
      final requestModel = AkHotelSearchInitRequestModel.fromEntity(request);
      final response = await apiService.searchInit(requestModel);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelSearchInitModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/init/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to start hotel search',
        ),
      );
    } on DioException catch (e) {
      print('Search Init Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Search Init Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/search/init/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
