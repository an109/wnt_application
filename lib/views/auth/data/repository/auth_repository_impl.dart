import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entity/user_entity.dart';
import '../../domain/repository/auth_repository.dart';
import '../../../../core/constants/urls.dart';
import '../data_source/auth_api_source.dart';
import '../model/google_auth_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService authApiService;

  AuthRepositoryImpl(this.authApiService);

  @override
  Future<DataState<UserEntity>> googleLogin(String idToken) async {
    try {
      print('Repository: Starting google login with token: ${idToken.substring(0, 20)}...');

      final requestModel = GoogleAuthRequestModel(idToken: idToken);
      final response = await authApiService.googleLogin(requestModel);

      print('Repository: Response success: ${response.success}, message: ${response.message}');

      // FIX: Check success AND user existence
      if (response.success == true && response.user != null) {
        print('Repository: Login successful, returning user');

        // Optional: Store tokens if your backend returns them
        if (response.tokens != null) {
          final prefs = di.sl<PreferencesManager>();
          await prefs.saveToken(response.tokens!['access']);
          // await prefs.saveRefreshToken(response.tokens!['refresh']);
          // await prefs.saveUserType(response.user!.userType);
        }

        return DataSuccess(response.user!);
      } else {
        print('Repository: Login failed - ${response.message}');
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: Urls.googleAuth),
            message: response.message ?? 'Authentication failed',
            response: Response(
              requestOptions: RequestOptions(path: Urls.googleAuth),
              statusCode: 400,
              data: response.error,
            ),
          ),
        );
      }
    } on DioException catch (e) {
      print('Repository: DioException - ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Repository: Unknown error - $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: Urls.googleAuth),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}