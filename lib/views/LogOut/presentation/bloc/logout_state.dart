import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/logout_entity.dart';

abstract class LogoutState extends Equatable {
  const LogoutState();

  @override
  List<Object?> get props => [];
}

class LogoutInitial extends LogoutState {}

class LogoutLoading extends LogoutState {}

class LogoutSuccess extends LogoutState {
  final LogoutEntity logoutEntity;

  const LogoutSuccess(this.logoutEntity);

  @override
  List<Object?> get props => [logoutEntity];
}

class LogoutFailed extends LogoutState {
  final DioException error;

  const LogoutFailed(this.error);

  @override
  List<Object?> get props => [error];
}