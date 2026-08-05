import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKFlights_entity.dart';
import '../../domain/repository/AKFlights_repository.dart';
import '../data_source/AKFlights_api_service.dart';
import '../model/AKFlights_model.dart';

class AkflightsRepositoryImpl implements AkflightsRepository {
  final AkflightsApiService apiService;

  AkflightsRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkflightsSearchEntity>> getExpSearch({
    required String tui,
  }) async {
    try {
      final response = await apiService.getExpSearch(tui: tui);

      if (response.statusCode == 200) {
        final akflightsSearchModel = AkflightsSearchModel.fromJson(response.data);
        return DataSuccess(akflightsSearchModel);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/GetExpSearch/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch flights',
          ),
        );
      }
    } on DioException catch (e) {
      print('Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/GetExpSearch/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}