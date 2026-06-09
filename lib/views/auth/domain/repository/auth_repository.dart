
import '../../../../core/error/data_state.dart';
import '../entity/user_entity.dart';

abstract class AuthRepository {
  Future<DataState<UserEntity>> googleLogin(String idToken);

  Future<DataState<UserEntity>> appleLogin({
    required String token,
    String? firstName,
    String? lastName,
    String? email,
  });
}