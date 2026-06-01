
import '../../domain/entity/logout_entity.dart';

class LogoutModel extends LogoutEntity {
  LogoutModel({
    required bool success,
    required String message,
    required int tokensDeleted,
  }) : super(
    success: success,
    message: message,
    tokensDeleted: tokensDeleted,
  );

  factory LogoutModel.fromJson(Map<String, dynamic> json) {
    return LogoutModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      tokensDeleted: json['tokens_deleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'tokens_deleted': tokensDeleted,
    };
  }
}