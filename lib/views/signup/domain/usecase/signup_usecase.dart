import '../../../../core/error/data_state.dart';
import '../entity/signup_entity.dart';
import '../repository/signup_repository.dart';

class SignupUseCase {
  final SignupRepository repository;

  SignupUseCase(this.repository);

  Future<DataState<SignupEntity>> call({
    required String firstname,
    required String lastname,
    required String password,
    String? email,
    String? phone,
    String? phoneCode,
  }) {
    return repository.signup(
      firstname: firstname,
      lastname: lastname,
      password: password,
      email: email,
      phone: phone,
      phoneCode: phoneCode,
    );
  }
}