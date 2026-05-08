import '../../../../core/error/data_state.dart';
import '../entity/user_entity.dart';
import '../repository/auth_repository.dart';

class GoogleLoginUseCase {
  final AuthRepository repository;

  GoogleLoginUseCase(this.repository);

  Future<DataState<UserEntity>> call(String idToken) async {
    print('🔄 UseCase: Executing google login');
    return await repository.googleLogin(idToken);
  }
}