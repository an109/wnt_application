import '../../../../core/error/data_state.dart';
import '../entity/user_entity.dart';
import '../repository/auth_repository.dart';

class AppleLoginUseCase {
  final AuthRepository repository;

  AppleLoginUseCase(this.repository);

  Future<DataState<UserEntity>> call({
    required String token,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    print('🔄 UseCase: Executing apple login');
    return await repository.appleLogin(
      token: token,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
  }
}
