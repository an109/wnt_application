import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/TResult_entity.dart';
import '../../domain/repository/TResult_repository.dart';
import '../data_source/TResult_api_service.dart';
import '../model/TResult_model.dart';

class TransportResultRepositoryImpl implements TransportResultRepository {
  final TransportResultApiService apiService;

  TransportResultRepositoryImpl(this.apiService);

  @override
  Future<DataState<TransportResultEntity>> getTransportResult({
    required String searchId,
    required String resultId,
  }) async {
    try {
      final response = await apiService.getTransportResult(
        searchId: searchId,
        resultId: resultId,
      );

      if (response.statusCode == 200) {
        final transportResult = TransportResultModel.fromJson(response.data);
        return DataSuccess(transportResult);
      } else {
        return  DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to fetch transport result',
            type: DioExceptionType.badResponse,
            response: null,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}