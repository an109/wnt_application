import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKSsr_entity.dart';
import '../../domain/repository/AKSsr_repository.dart';
import '../data_source/AKSsr_api_service.dart';
import '../model/AKSsr_model.dart';

class AkSsrRepositoryImpl implements AkSsrRepository {
  final AkSsrApiService apiService;

  AkSsrRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkSsrEntity>> getSsr(AkSsrRequestEntity request) async {
    try {
      final requestModel = AkSsrRequestModel.fromEntity(request);
      final response = await apiService.getSsr(requestModel);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = AkSsrModel.fromJson(response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/SSR/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to fetch SSR options',
          ),
        );
      }
    } on DioException catch (e) {
      print('SSR Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('SSR Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/SSR/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
