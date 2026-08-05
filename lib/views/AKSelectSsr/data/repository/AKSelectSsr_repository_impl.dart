import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKSelectSsr_entity.dart';
import '../../domain/repository/AKSelectSsr_repository.dart';
import '../data_source/AKSelectSsr_api_service.dart';
import '../model/AKSelectSsr_model.dart';

class AkSelectSsrRepositoryImpl implements AkSelectSsrRepository {
  final AkSelectSsrApiService apiService;

  AkSelectSsrRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkSelectSsrEntity>> selectSsr(AkSelectSsrRequestEntity request) async {
    try {
      final requestModel = AkSelectSsrRequestModel.fromEntity(request);
      final response = await apiService.selectSsr(requestModel);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = AkSelectSsrModel.fromJson(response.data as Map<String, dynamic>);
        return DataSuccess(model);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: '/api/akbar/SelectSSR/'),
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Failed to select SSR add-ons',
          ),
        );
      }
    } on DioException catch (e) {
      print('SelectSSR Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('SelectSSR Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar/SelectSSR/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
