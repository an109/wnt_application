import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKSelectSeats_entity.dart';
import '../../domain/repository/AKSelectSeats_repository.dart';
import '../data_source/AKSelectSeats_api_service.dart';
import '../model/AKSelectSeats_model.dart';

class AkSelectSeatsRepositoryImpl implements AkSelectSeatsRepository {
  final AkSelectSeatsApiService apiService;

  AkSelectSeatsRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkSelectSeatsEntity>> selectSeats(
      AkSelectSeatsRequestEntity request) async {
    try {
      final requestModel = AkSelectSeatsRequestModel.fromEntity(request);
      final response = await apiService.selectSeats(requestModel);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = AkSelectSeatsModel.fromJson(response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/SelectSeats/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to select seats',
          ),
        );
      }
    } on DioException catch (e) {
      print('SelectSeats Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('SelectSeats Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/SelectSeats/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
