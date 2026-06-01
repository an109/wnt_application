import 'package:equatable/equatable.dart';

class LogoutEntity extends Equatable {
  final bool success;
  final String message;
  final int tokensDeleted;

  const LogoutEntity({
    required this.success,
    required this.message,
    required this.tokensDeleted,
  });

  @override
  List<Object?> get props => [success, message, tokensDeleted];
}