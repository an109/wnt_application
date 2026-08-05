import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKStartPay_entity.dart';
import '../../domain/repository/AKStartPay_repository.dart';
import '../data_source/AKStartPay_api_service.dart';
import '../model/AKStartPay_model.dart';

class AkStartPayRepositoryImpl implements AkStartPayRepository {
  final AkStartPayApiService apiService;

  AkStartPayRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkStartPayEntity>> startPay(AkStartPayRequestEntity request) async {
    try {
      final requestModel = AkStartPayRequestModel.fromEntity(request);
      final response = await apiService.startPay(requestModel);
      final data = response.data;

      if (response.statusCode == 202 && data is Map<String, dynamic>) {
        return DataSuccess(AkStartPayModel.bookingInProgress(data));
      }

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkStartPayModel.fromJson(data));
      }

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/StartPay/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to start payment/ticketing',
        ),
      );
    } on DioException catch (e) {
      print('StartPay Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('StartPay Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/StartPay/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
