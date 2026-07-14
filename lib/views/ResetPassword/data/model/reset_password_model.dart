import '../../domain/entity/reset_password_entity.dart';

class ResetPasswordModel extends ResetPasswordEntity {
  const ResetPasswordModel({
    required super.success,
    required super.message,
  });

  factory ResetPasswordModel.fromJson(Map<String, dynamic> json) {
    return ResetPasswordModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
