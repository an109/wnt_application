import '../../../../core/error/data_state.dart';
import '../entity/login_entity.dart';

abstract class LoginRepository {
  Future<DataState<LoginEntity>> login({
    required String contactValue,
    required String password,
    required String contactType,
  });
}