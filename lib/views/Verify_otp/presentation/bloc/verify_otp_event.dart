import 'package:equatable/equatable.dart';

import '../../../../UI_helper/contact_type.dart';

abstract class VerifyOtpEvent extends Equatable {
  const VerifyOtpEvent();

  @override
  List<Object?> get props => [];
}

class VerifyOtpRequested extends VerifyOtpEvent {
  final String contact;
  final ContactType type;
  final String otp;

  const VerifyOtpRequested({
    required this.contact,
    required this.type,
    required this.otp,
  });

  @override
  List<Object?> get props => [contact, type, otp];
}

class VerifyOtpReset extends VerifyOtpEvent {
  const VerifyOtpReset();
}