import 'package:equatable/equatable.dart';

class ResetPasswordEntity extends Equatable {
  final bool success;
  final String message;

  const ResetPasswordEntity({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];
}
