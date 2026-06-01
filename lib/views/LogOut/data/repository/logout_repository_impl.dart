import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/error/data_state.dart';
import '../../data/data_source/logout_api_service.dart';
import '../../domain/entity/logout_entity.dart';
import '../../domain/repository/logout_repository.dart';
import '../model/logout_model.dart';

class LogoutRepositoryImpl implements LogoutRepository {
  final LogoutApiService apiService;

  LogoutRepositoryImpl(this.apiService);

  @override
  Future<DataState<LogoutEntity>> logout() async {
    try {
      final response = await apiService.logout();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final logoutModel = LogoutModel.fromJson(response.data);
        return DataSuccess(logoutModel);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: response.requestOptions.path),
            response: response,
            error: response.statusMessage ?? 'Unknown error',
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: Urls.logout),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}