import 'package:equatable/equatable.dart';

class SignupEntity extends Equatable {
  final bool success;
  final String message;
  final UserEntity user;
  final TokensEntity tokens;

  const SignupEntity({
    required this.success,
    required this.message,
    required this.user,
    required this.tokens,
  });

  @override
  List<Object?> get props => [success, message, user, tokens];
}

class UserEntity extends Equatable {
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

  const UserEntity({
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

class TokensEntity extends Equatable {
  final String refresh;
  final String access;

  const TokensEntity({
    required this.refresh,
    required this.access,
  });

  @override
  List<Object?> get props => [refresh, access];
}