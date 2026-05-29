import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/login_entity.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final LoginEntity loginEntity;

  const LoginSuccess(this.loginEntity);

  @override
  List<Object?> get props => [loginEntity];

  @override
  String toString() {
    return 'LoginSuccess{user: ${loginEntity.user.firstname}}';
  }
}

class LoginFailure extends LoginState {
  final String errorMessage;
  final DioException? dioError;

  const LoginFailure(this.errorMessage, {this.dioError});

  @override
  List<Object?> get props => [errorMessage, dioError];

  @override
  String toString() {
    return 'LoginFailure{errorMessage: $errorMessage}';
  }
}

class LoginValidationError extends LoginState {
  final String field;
  final String message;

  const LoginValidationError(this.field, this.message);

  @override
  List<Object?> get props => [field, message];
}