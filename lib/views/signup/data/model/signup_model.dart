import 'package:equatable/equatable.dart';

import '../../domain/entity/signup_entity.dart';

class SignupModel extends Equatable {
  final bool success;
  final String message;
  final UserModel user;
  final TokensModel tokens;

  const SignupModel({
    required this.success,
    required this.message,
    required this.user,
    required this.tokens,
  });

  factory SignupModel.fromJson(Map<String, dynamic> json) {
    return SignupModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      tokens: TokensModel.fromJson(json['tokens'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user': user.toJson(),
      'tokens': tokens.toJson(),
    };
  }

  SignupEntity toEntity() {
    return SignupEntity(
      success: success,
      message: message,
      user: user.toEntity(),
      tokens: tokens.toEntity(),
    );
  }

  @override
  List<Object?> get props => [success, message, user, tokens];
}

class UserModel extends Equatable {
  final int id;
  final String firstname;
  final String lastname;
  final String? email;
  final String platform;
  final String phoneCode;
  final String phoneNumber;
  final String created;
  final String updated;
  final bool isloggedin;

  const UserModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.email,
    required this.platform,
    required this.phoneCode,
    required this.phoneNumber,
    required this.created,
    required this.updated,
    required this.isloggedin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'],
      platform: json['platform'] ?? '',
      phoneCode: json['phone_code'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      created: json['created'] ?? '',
      updated: json['updated'] ?? '',
      isloggedin: json['isloggedin'] ?? false,
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

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      firstname: firstname,
      lastname: lastname,
      email: email,
      platform: platform,
      phoneCode: phoneCode,
      phoneNumber: phoneNumber,
      created: created,
      updated: updated,
      isloggedin: isloggedin,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstname,
    lastname,
    email,
    platform,
    phoneCode,
    phoneNumber,
    created,
    updated,
    isloggedin,
  ];
}

class TokensModel extends Equatable {
  final String refresh;
  final String access;

  const TokensModel({
    required this.refresh,
    required this.access,
  });

  factory TokensModel.fromJson(Map<String, dynamic> json) {
    return TokensModel(
      refresh: json['refresh'] ?? '',
      access: json['access'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refresh': refresh,
      'access': access,
    };
  }

  TokensEntity toEntity() {
    return TokensEntity(
      refresh: refresh,
      access: access,
    );
  }

  @override
  List<Object?> get props => [refresh, access];
}