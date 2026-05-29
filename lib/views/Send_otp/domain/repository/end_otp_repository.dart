import '../../../../UI_helper/contact_type.dart';
import '../../../../core/error/data_state.dart';
import '../../presentation/bloc/send_otp_event.dart';
import '../entity/send_otp_Entity.dart';

abstract class SendOtpRepository {
  Future<DataState<SendOtpEntity>> sendOtp({required String contact, required ContactType type, required String purpose});
}