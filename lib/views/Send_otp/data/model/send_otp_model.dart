import '../../../../views/Send_otp/domain/entity/send_otp_Entity.dart';

class SendOtpModel extends SendOtpEntity {
  const SendOtpModel({
    required super.success,
    required super.message,
    required super.userExists,
  });

  factory SendOtpModel.fromJson(Map<String, dynamic> json) {
    return SendOtpModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      userExists: json['user_exists'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user_exists': userExists,
    };
  }
}