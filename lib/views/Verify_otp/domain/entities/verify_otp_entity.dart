import 'package:equatable/equatable.dart';

class VerifyOtpEntity extends Equatable {
  final bool success;
  final String message;
  final bool userExists;

  const VerifyOtpEntity({
    required this.success,
    required this.message,
    required this.userExists,
  });

  @override
  List<Object?> get props => [success, message, userExists];
}