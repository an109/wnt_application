import '../../domain/entity/user_entity.dart';

class GoogleAuthResponseModel {
  final bool? success;
  final String? message;
  final UserEntity? user;
  final Map<String, dynamic>? error;
  final Map<String, dynamic>? tokens;
  final bool? created;
  final Map<String, dynamic>? rawData;

  GoogleAuthResponseModel({
    this.success,
    this.message,
    this.user,
    this.error,
    this.tokens,
    this.created,
    this.rawData,
  });

  factory GoogleAuthResponseModel.fromJson(Map<String, dynamic> json) {
    return GoogleAuthResponseModel(
      success: json['success'],
      message: json['message'],
      // FIX: Look for 'user' field, not 'data'
      user: json['user'] != null ? UserEntity.fromJson(json['user']) : null,
      error: json['error'],
      tokens: json['tokens'],
      created: json['created'],
      rawData: json,
    );
  }
}