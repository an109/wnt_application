import 'package:equatable/equatable.dart';

class SendOtpEntity extends Equatable {
  final bool success;
  final String message;
  final bool userExists;

  const SendOtpEntity({
    required this.success,
    required this.message,
    required this.userExists,
  });

  @override
  List<Object?> get props => [success, message, userExists];
}