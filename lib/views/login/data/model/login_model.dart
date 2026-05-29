import '../../domain/entity/login_entity.dart';

class LoginModel extends LoginEntity {
  const LoginModel({
    required super.success,
    required super.message,
    required super.user,
    required super.tokens,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : const UserModel(),
      tokens: json['tokens'] != null
          ? TokensModel.fromJson(json['tokens'] as Map<String, dynamic>)
          : const TokensModel(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user': (user as UserModel?)?.toJson(),
      'tokens': (tokens as TokensModel?)?.toJson(),
    };
  }
}

class UserModel extends UserEntity {
  const UserModel({
    super.id,
    super.firstname,
    super.lastname,
    super.email,
    super.platform,
    super.phoneCode,
    super.phoneNumber,
    super.created,
    super.updated,
    super.isloggedin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      email: json['email'] as String?,
      platform: json['platform'] as String?,
      phoneCode: json['phone_code'] as String?,
      phoneNumber: json['phone_number'] as String?,
      created: json['created'] as String?,
      updated: json['updated'] as String?,
      isloggedin: json['isloggedin'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'platform': platform,
      'phone_code': phoneCode,
      'phone_number': phoneNumber,
      'created': created,
      'updated': updated,
      'isloggedin': isloggedin,
    };
  }
}

class TokensModel extends TokensEntity {
  const TokensModel({
    super.refresh,
    super.access,
  });

  factory TokensModel.fromJson(Map<String, dynamic> json) {
    return TokensModel(
      refresh: json['refresh'] as String?,
      access: json['access'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refresh': refresh,
      'access': access,
    };
  }
}