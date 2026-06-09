import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class GoogleLoginRequested extends AuthEvent {
  final String idToken;

  const GoogleLoginRequested(this.idToken);

  @override
  List<Object?> get props => [idToken];
}

class AppleLoginRequested extends AuthEvent {
  final String token;
  final String? firstName;
  final String? lastName;
  final String? email;

  const AppleLoginRequested({
    required this.token,
    this.firstName,
    this.lastName,
    this.email,
  });

  @override
  List<Object?> get props => [token, firstName, lastName, email];
}

class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}