import '../../../../core/error/data_state.dart';
import '../entity/signup_entity.dart';

abstract class SignupRepository {
  Future<DataState<SignupEntity>> signup({
    required String firstname,
    required String lastname,
    required String password,
    required String phone,
    required String phoneCode,
  });
}