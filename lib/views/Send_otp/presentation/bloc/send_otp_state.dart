import 'package:equatable/equatable.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/send_otp_Entity.dart';

abstract class SendOtpState extends Equatable {
  const SendOtpState();

  @override
  List<Object?> get props => [];
}

class SendOtpInitial extends SendOtpState {
  const SendOtpInitial();
}

class SendOtpLoading extends SendOtpState {
  const SendOtpLoading();
}

class SendOtpSuccess extends SendOtpState {
  final SendOtpEntity sendOtpEntity;

  const SendOtpSuccess(this.sendOtpEntity);

  @override
  List<Object?> get props => [sendOtpEntity];
}

class SendOtpFailed extends SendOtpState {
  final DataState<dynamic> dataState;

  const SendOtpFailed(this.dataState);

  @override
  List<Object?> get props => [dataState];
}