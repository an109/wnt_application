import '../../../../UI_helper/contact_type.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../../core/error/data_state.dart';
import '../entities/verify_otp_entity.dart';

abstract class VerifyOtpRepository {
  Future<DataState<VerifyOtpEntity>> verifyOtp({
    required String contact,
    required ContactType type,
    required String otp,
  });
}