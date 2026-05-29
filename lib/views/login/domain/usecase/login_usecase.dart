import '../../../../core/error/data_state.dart';
import '../entity/login_entity.dart';
import '../repository/login_repository.dart';

class LoginUseCase {
  final LoginRepository repository;

  LoginUseCase(this.repository);

  Future<DataState<LoginEntity>> call({
    required String contactValue,
    required String password,
    required String contactType,
  }) {
    print('Executing LoginUseCase with contactType: $contactType');
    return repository.login(
      contactValue: contactValue,
      password: password,
      contactType: contactType,
    );
  }
}