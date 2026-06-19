import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/poll_entity.dart';
import '../../domain/repository/poll_repository.dart';
import '../data_source/poll_api_service.dart';
import '../model/poll_model.dart';

class ReservationPollRepositoryImpl implements ReservationPollRepository {
  final ReservationPollApiService _apiService;

  ReservationPollRepositoryImpl(this._apiService);

  @override
  Future<DataState<ReservationPollEntity>> getReservationPoll({required String searchId}) async {
    try {
      final response = await _apiService.getReservationPoll(searchId: searchId);

      if (response.statusCode == 200) {
        final model = ReservationPollResponseModel.fromJson(response.data);
        return DataSuccess(model.toEntity());
      } else {
        return DataFailed(
          DioException(
            error: 'Failed to fetch reservation poll',
            response: response,
            type: DioExceptionType.badResponse,
            requestOptions: response.requestOptions,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}