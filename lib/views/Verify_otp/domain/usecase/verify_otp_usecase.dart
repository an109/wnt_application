import '../../../../UI_helper/contact_type.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../../core/error/data_state.dart';
import '../entities/verify_otp_entity.dart';
import '../repository/verify_otp_repository.dart';

class VerifyOtpUseCase {
  final VerifyOtpRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<DataState<VerifyOtpEntity>> call({
    required String contact,
    required ContactType type,
    required String otp,
  }) {
    return repository.verifyOtp(
      contact: contact,
      type: type,
      otp: otp,
    );
  }
}