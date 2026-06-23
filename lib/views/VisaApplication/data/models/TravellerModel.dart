import '../../domain/entity/TravellerEntity.dart';

class TravellerModel extends TravellerEntity {
  const TravellerModel({
    super.id,
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
      id: json['id'] as int?,
      travellerIndex: json['travellerIndex'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      passportNo: json['passportNo'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      emailId: json['emailId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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

  factory TravellerModel.fromEntity(TravellerEntity entity) {
    return TravellerModel(
      id: entity.id,
      travellerIndex: entity.travellerIndex,
      title: entity.title,
      firstName: entity.firstName,
      lastName: entity.lastName,
      dob: entity.dob,
      nationality: entity.nationality,
      passportNo: entity.passportNo,
      contactNumber: entity.contactNumber,
      emailId: entity.emailId,
    );
  }
}