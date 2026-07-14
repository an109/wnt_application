import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/reset_password_entity.dart';
import '../../domain/repository/reset_password_repository.dart';
import '../data_source/reset_password_api_service.dart';

class ResetPasswordRepositoryImpl implements ResetPasswordRepository {
  final ResetPasswordApiService apiService;

  ResetPasswordRepositoryImpl(this.apiService);

  @override
  Future<DataState<ResetPasswordEntity>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await apiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return DataSuccess(response);
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
