
import '../../../../core/error/data_state.dart';
import '../entity/user_entity.dart';

abstract class AuthRepository {
  Future<DataState<UserEntity>> googleLogin(String idToken);
}