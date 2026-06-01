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
    Map<String, dynamic>? userWithTokens;

    if (json['user'] != null) {
      // Start with user data
      userWithTokens = Map<String, dynamic>.from(json['user']);

      // Add tokens to the same map
      if (json['tokens'] != null) {
        userWithTokens['tokens'] = json['tokens'];
      }
    }

    return GoogleAuthResponseModel(
      success: json['success'],
      message: json['message'],
      user: userWithTokens != null ? UserEntity.fromJson(userWithTokens) : null,
      error: json['error'],
      tokens: json['tokens'],
      created: json['created'],
      rawData: json,
    );
  }
}