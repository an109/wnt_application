import 'package:equatable/equatable.dart';

class DeleteAccountEntity extends Equatable {
  final bool success;
  final String message;

  const DeleteAccountEntity({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];
}
