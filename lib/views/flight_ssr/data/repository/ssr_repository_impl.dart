import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../data/data_source/ssr_api_service.dart';
import '../../data/models/ssr_request_model.dart';
import '../../data/models/ssr_response_model.dart';
import '../../domain/entities/ssr_entity.dart';
import '../../domain/repository/ssr_repository.dart';

class SsrRepositoryImpl implements SsrRepository {
  final SsrApiService apiService;

  SsrRepositoryImpl(this.apiService);

  @override
  Future<DataState<SsrEntity>> getSsrData({
    required String endUserIp,
    required String traceId,
    required String tokenId,
    required String resultIndex,
  }) async {
    try {
      final requestModel = SsrRequestModel(
        endUserIp: endUserIp,
        traceId: traceId,
        tokenId: tokenId,
        resultIndex: resultIndex,
      );

      final response = await apiService.getSsrData(requestModel);

      if (response.statusCode == 200 && response.data != null) {
        final ssrResponse = SsrResponseModel.fromJson(response.data);
        final entity = _mapToEntity(ssrResponse);
        return DataSuccess(entity);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: response.requestOptions.path),
            error: 'Invalid response: ${response.statusCode}',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: 'ssr'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  SsrEntity _mapToEntity(SsrResponseModel model) {
    return SsrEntity(
      responseStatus: model.response?.responseStatus,
      errorCode: model.response?.error?.errorCode,
      errorMessage: model.response?.error?.errorMessage,
      traceId: model.response?.traceId,
      baggage: model.response?.baggage,
      mealDynamic: model.response?.mealDynamic,
      seatDynamic: model.response?.seatDynamic,
      specialServices: model.response?.specialServices,
    );
  }
}