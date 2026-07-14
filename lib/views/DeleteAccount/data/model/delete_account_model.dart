import '../../domain/entity/delete_account_entity.dart';

class DeleteAccountModel extends DeleteAccountEntity {
  DeleteAccountModel({
    required bool success,
    required String message,
  }) : super(
    success: success,
    message: message,
  );

  factory DeleteAccountModel.fromJson(Map<String, dynamic> json) {
    return DeleteAccountModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
