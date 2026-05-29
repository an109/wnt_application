import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String contactValue;
  final String password;
  final String contactType; // 'email' or 'phone'

  const LoginSubmitted({
    required this.contactValue,
    required this.password,
    required this.contactType,
  });

  @override
  List<Object?> get props => [contactValue, password, contactType];

  @override
  String toString() {
    return 'LoginSubmitted{contactValue: $contactValue, contactType: $contactType, password: ***}';
  }
}

class LoginReset extends LoginEvent {
  const LoginReset();
}