import 'package:equatable/equatable.dart';

class TravellerEntity extends Equatable {
  final int? id;
  final int travellerIndex;
  final String title;
  final String firstName;
  final String lastName;
  final String dob;
  final String nationality;
  final String passportNo;
  final String contactNumber;
  final String emailId;

  const TravellerEntity({
    this.id,
    required this.travellerIndex,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.nationality,
    required this.passportNo,
    required this.contactNumber,
    required this.emailId,
  });

  @override
  List<Object?> get props => [
    id,
    travellerIndex,
    title,
    firstName,
    lastName,
    dob,
    nationality,
    passportNo,
    contactNumber,
    emailId,
  ];
}