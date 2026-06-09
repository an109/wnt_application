import 'package:equatable/equatable.dart';

abstract class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => [];
}

class SignupSubmitted extends SignupEvent {
  final String firstname;
  final String lastname;
  final String password;
  final String? email;
  final String? phone;
  final String? phoneCode;

  const SignupSubmitted({
    required this.firstname,
    required this.lastname,
    required this.password,
    this.email,
    this.phone,
    this.phoneCode,
  });

  @override
  List<Object?> get props =>
      [firstname, lastname, password, email, phone, phoneCode];
}

class SignupReset extends SignupEvent {}