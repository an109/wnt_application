import '../../../../core/error/data_state.dart';
import '../entity/reset_password_entity.dart';
import '../repository/reset_password_repository.dart';

class ResetPasswordUseCase {
  final ResetPasswordRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<DataState<ResetPasswordEntity>> call({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return repository.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }
}
