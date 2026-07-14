import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/reset_password_entity.dart';

abstract class ResetPasswordState extends Equatable {
  const ResetPasswordState();

  @override
  List<Object?> get props => [];
}

class ResetPasswordInitial extends ResetPasswordState {
  const ResetPasswordInitial();
}

class ResetPasswordLoading extends ResetPasswordState {
  const ResetPasswordLoading();
}

class ResetPasswordSuccess extends ResetPasswordState {
  final ResetPasswordEntity resetPasswordEntity;

  const ResetPasswordSuccess(this.resetPasswordEntity);

  @override
  List<Object?> get props => [resetPasswordEntity];
}

class ResetPasswordFailed extends ResetPasswordState {
  final DataState<dynamic> dataState;

  const ResetPasswordFailed(this.dataState);

  @override
  List<Object?> get props => [dataState];
}
