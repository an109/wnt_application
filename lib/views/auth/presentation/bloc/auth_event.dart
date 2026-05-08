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

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}