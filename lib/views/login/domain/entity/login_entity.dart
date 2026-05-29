import 'package:equatable/equatable.dart';

class LoginEntity extends Equatable {
  final bool success;
  final String message;
  final UserEntity user;
  final TokensEntity tokens;

  const LoginEntity({
    required this.success,
    required this.message,
    required this.user,
    required this.tokens,
  });

  @override
  List<Object?> get props => [success, message, user, tokens];
}

class UserEntity extends Equatable {
  final int? id;
  final String? firstname;
  final String? lastname;
  final String? email;
  final String? platform;
  final String? phoneCode;
  final String? phoneNumber;
  final String? created;
  final String? updated;
  final bool? isloggedin;

  const UserEntity({
    this.id,
    this.firstname,
    this.lastname,
    this.email,
    this.platform,
    this.phoneCode,
    this.phoneNumber,
    this.created,
    this.updated,
    this.isloggedin,
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
  final String? refresh;
  final String? access;

  const TokensEntity({
    this.refresh,
    this.access,
  });

  @override
  List<Object?> get props => [refresh, access];
}