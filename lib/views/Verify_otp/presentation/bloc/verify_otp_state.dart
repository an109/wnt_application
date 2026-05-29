import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/verify_otp_entity.dart';

abstract class VerifyOtpState extends Equatable {
  const VerifyOtpState();

  @override
  List<Object?> get props => [];
}

class VerifyOtpInitial extends VerifyOtpState {
  const VerifyOtpInitial();
}

class VerifyOtpLoading extends VerifyOtpState {
  const VerifyOtpLoading();
}

class VerifyOtpSuccess extends VerifyOtpState {
  final VerifyOtpEntity verifyOtpEntity;

  const VerifyOtpSuccess(this.verifyOtpEntity);

  @override
  List<Object?> get props => [verifyOtpEntity];
}

class VerifyOtpFailed extends VerifyOtpState {
  final DataState<dynamic> dataState;

  const VerifyOtpFailed(this.dataState);

  @override
  List<Object?> get props => [dataState];
}