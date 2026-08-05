import '../../domain/entity/AKAcceptFareChange_entity.dart';

class AkAcceptFareChangeRequestModel extends AkAcceptFareChangeRequestEntity {
  const AkAcceptFareChangeRequestModel({required super.sessionId});

  factory AkAcceptFareChangeRequestModel.fromEntity(AkAcceptFareChangeRequestEntity entity) {
    return AkAcceptFareChangeRequestModel(sessionId: entity.sessionId);
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
    };
  }
}

class AkAcceptFareChangeModel extends AkAcceptFareChangeEntity {
  const AkAcceptFareChangeModel({required super.success});

  factory AkAcceptFareChangeModel.fromJson(Map<String, dynamic> json) {
    return AkAcceptFareChangeModel(success: json['success'] ?? false);
  }
}
