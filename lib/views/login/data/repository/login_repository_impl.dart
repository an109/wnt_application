import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/login_entity.dart';
import '../../domain/repository/login_repository.dart';
import '../data_source/login_api_service.dart';
import '../model/login_model.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginApiService loginApiService;

  LoginRepositoryImpl(this.loginApiService);

  @override
  Future<DataState<LoginEntity>> login({
    required String contactValue,
    required String password,
    required String contactType,
  }) async {
    try {
      final response = await loginApiService.login(
        contactValue: contactValue,
        password: password,
        contactType: contactType,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginModel = LoginModel.fromJson(response.data);

        print('Login successful for user: ${loginModel.user.firstname}');
        return DataSuccess<LoginEntity>(loginModel);
      } else {
        print('Login failed with status: ${response.statusCode}');
        return DataFailed<LoginEntity>(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login/'),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on DioException catch (e) {
      print('Login Repository DioException: ${e.message}');
      return DataFailed<LoginEntity>(e);
    } catch (e) {
      print('Login Repository Unknown Error: $e');
      return DataFailed<LoginEntity>(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}