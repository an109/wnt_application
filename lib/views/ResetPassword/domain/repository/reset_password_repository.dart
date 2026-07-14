import '../../../../core/error/data_state.dart';
import '../entity/reset_password_entity.dart';

abstract class ResetPasswordRepository {
  Future<DataState<ResetPasswordEntity>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}
