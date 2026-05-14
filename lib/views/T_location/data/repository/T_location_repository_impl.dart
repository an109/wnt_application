import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/repository/T_location_repository.dart';
import '../data_source/T_loaction_api_service.dart';

class T_locationRepositoryImpl implements T_locationRepository {
  final T_locationApiService apiService;

  T_locationRepositoryImpl(this.apiService);

  @override
  Future<DataState<Response>> getT_locations({
    String? country,
    String? searchQuery,
  }) async {
    try {
      final response = await apiService.getT_locations(
        country: country,
        searchQuery: searchQuery,
      );

      if (response.statusCode == 200) {
        return DataSuccess(response);
      } else {
        return DataFailed(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to load locations: ${response.statusCode}',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'getT_locations'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}