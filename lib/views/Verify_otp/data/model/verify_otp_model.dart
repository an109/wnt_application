import '../../domain/entities/verify_otp_entity.dart';

class VerifyOtpModel extends VerifyOtpEntity {
  const VerifyOtpModel({
    required super.success,
    required super.message,
    required super.userExists,
  });

  factory VerifyOtpModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpModel(
      success: json['success'] ?? false,
      message: json['message'] ?? json['error'] ?? '',
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