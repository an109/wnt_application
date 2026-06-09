import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/signup_entity.dart';
import '../../domain/repository/signup_repository.dart';
import '../data_source/signup_api_service.dart';
import '../model/signup_model.dart';

class SignupRepositoryImpl implements SignupRepository {
  final SignupApiService apiService;

  SignupRepositoryImpl(this.apiService);

  @override
  Future<DataState<SignupEntity>> signup({
    required String firstname,
    required String lastname,
    required String password,
    String? email,
    String? phone,
    String? phoneCode,
  }) async {
    try {
      final response = await apiService.signup(
        firstname: firstname,
        lastname: lastname,
        password: password,
        email: email,
        phone: phone,
        phoneCode: phoneCode,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final signupModel = SignupModel.fromJson(response.data);
        return DataSuccess(signupModel.toEntity());
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: response.requestOptions.path),
            error: response.statusMessage ?? 'Unexpected status code',
            response: response,
            type: DioExceptionType.badResponse,
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