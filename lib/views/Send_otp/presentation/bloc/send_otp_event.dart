// import 'package:equatable/equatable.dart';
//
// enum ContactType { email, phone }
//
// abstract class SendOtpEvent extends Equatable {
//   const SendOtpEvent();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class SendOtpRequested extends SendOtpEvent {
//   final String contact;      // Changed from 'email' to 'contact'
//   final ContactType type;    // NEW: identifies if it's email or phone
//   final String purpose;
//
//   const SendOtpRequested({
//     required this.contact,
//     required this.type,
//     this.purpose = 'signup',
//   });
//
//   @override
//   List<Object?> get props => [contact, type, purpose];
// }
//
//
// class SendOtpReset extends SendOtpEvent {
//   const SendOtpReset();
// }

import 'package:equatable/equatable.dart';
import '../../../../UI_helper/contact_type.dart';

// enum ContactType { email, phone }

abstract class SendOtpEvent extends Equatable {
  const SendOtpEvent();

  @override
  List<Object?> get props => [];
}

class SendOtpRequested extends SendOtpEvent {
  final String contact;
  final ContactType type;
  final String purpose;

  const SendOtpRequested({
    required this.contact,
    required this.type,
    this.purpose = 'signup',
  });

  @override
  List<Object?> get props => [contact, type, purpose];
}

class SendOtpReset extends SendOtpEvent {
  const SendOtpReset();
}