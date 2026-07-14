import 'package:equatable/equatable.dart';

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ResetPasswordRequested extends ResetPasswordEvent {
  final String email;
  final String otp;
  final String newPassword;

  const ResetPasswordRequested({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, otp, newPassword];
}

class ResetPasswordReset extends ResetPasswordEvent {
  const ResetPasswordReset();
}
