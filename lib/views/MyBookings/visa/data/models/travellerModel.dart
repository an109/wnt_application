
import '../../../../VisaApplication/domain/entity/TravellerEntity.dart';

class TravellerModel extends TravellerEntity {
  const TravellerModel({
    required super.id,
    required super.travellerIndex,
    required super.title,
    required super.firstName,
    required super.lastName,
    required super.dob,
    required super.nationality,
    required super.passportNo,
    required super.contactNumber,
    required super.emailId,
  });

  factory TravellerModel.fromJson(Map<String, dynamic> json) {
    return TravellerModel(
      id: json['id'] ?? 0,
      travellerIndex: json['travellerIndex'] ?? 0,
      title: json['title'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dob: json['dob'] ?? '',
      nationality: json['nationality'] ?? '',
      passportNo: json['passportNo'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      emailId: json['emailId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travellerIndex': travellerIndex,
      'title': title,
      'firstName': firstName,
      'lastName': lastName,
      'dob': dob,
      'nationality': nationality,
      'passportNo': passportNo,
      'contactNumber': contactNumber,
      'emailId': emailId,
    };
  }
}