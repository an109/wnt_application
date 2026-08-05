import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKSeatLayout_entity.dart';
import '../../domain/repository/AKSeatLayout_repository.dart';
import '../data_source/AKSeatLayout_api_service.dart';
import '../model/AKSeatLayout_model.dart';

class AkSeatLayoutRepositoryImpl implements AkSeatLayoutRepository {
  final AkSeatLayoutApiService apiService;

  AkSeatLayoutRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkSeatLayoutEntity>> getSeatLayout(
      AkSeatLayoutRequestEntity request) async {
    try {
      final requestModel = AkSeatLayoutRequestModel.fromEntity(request);
      final response = await apiService.getSeatLayout(requestModel);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = AkSeatLayoutModel.fromJson(response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/SeatLayout/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch seat layout',
          ),
        );
      }
    } on DioException catch (e) {
      print('SeatLayout Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('SeatLayout Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/SeatLayout/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
