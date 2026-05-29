import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/signup_entity.dart';

abstract class SignupState extends Equatable {
  const SignupState();

  @override
  List<Object?> get props => [];
}

class SignupInitial extends SignupState {}

class SignupLoading extends SignupState {}

class SignupSuccess extends SignupState {
  final SignupEntity signupEntity;

  const SignupSuccess(this.signupEntity);

  @override
  List<Object?> get props => [signupEntity];
}

class SignupFailed extends SignupState {
  final String errorMessage;

  const SignupFailed(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// Optional: Wrap your DataState for direct usage if needed
class SignupDataState extends SignupState {
  final DataState<SignupEntity> dataState;

  const SignupDataState(this.dataState);

  @override
  List<Object?> get props => [dataState];
}