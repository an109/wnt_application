import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../data/data_source/delete_account_api_service.dart';
import '../../domain/entity/delete_account_entity.dart';
import '../../domain/repository/delete_account_repository.dart';
import '../model/delete_account_model.dart';

class DeleteAccountRepositoryImpl implements DeleteAccountRepository {
  final DeleteAccountApiService apiService;
  final PreferencesManager preferencesManager;

  DeleteAccountRepositoryImpl(this.apiService, this.preferencesManager);

  @override
  Future<DataState<DeleteAccountEntity>> deleteAccount() async {
    try {
      final token = preferencesManager.getToken() ?? '';
      // Password is required only for normal email/phone + password logins;
      // Google/Apple sessions have none on file and skip it entirely.
      final password = preferencesManager.isSocialLogin() ? null : preferencesManager.getUserPassword();
      final response = await apiService.deleteAccount(token: token, password: password);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final deleteAccountModel = DeleteAccountModel.fromJson(response.data);
        return DataSuccess(deleteAccountModel);
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
          requestOptions: RequestOptions(path: Urls.deleteAccount),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
