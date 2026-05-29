import '../../../../UI_helper/contact_type.dart';
import '../../../../core/error/data_state.dart';
import '../../presentation/bloc/send_otp_event.dart';
import '../entity/send_otp_Entity.dart';
import '../repository/end_otp_repository.dart';

class SendOtpUseCase {
  final SendOtpRepository repository;

  SendOtpUseCase(this.repository);

  Future<DataState<SendOtpEntity>> call({
    required String contact,
    required ContactType type,
    required String purpose,
  }) {
    return repository.sendOtp(
      contact: contact,
      type: type,
      purpose: purpose,
    );
  }
}