import '../../domain/entity/AKSelectSeats_entity.dart';

class AkSelectedSeatItemModel extends AkSelectedSeatItemEntity {
  const AkSelectedSeatItemModel({
    required super.ssid,
    required super.fuid,
    required super.paxId,
    required super.fare,
    required super.tax,
  });

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'fuid': fuid,
      'pax_id': paxId,
      'fare': fare,
      'tax': tax,
    };
  }
}

class AkSelectSeatsRequestModel extends AkSelectSeatsRequestEntity {
  const AkSelectSeatsRequestModel({
    required super.sessionId,
    required super.selectedSeats,
  });

  factory AkSelectSeatsRequestModel.fromEntity(AkSelectSeatsRequestEntity entity) {
    return AkSelectSeatsRequestModel(
      sessionId: entity.sessionId,
      selectedSeats: entity.selectedSeats
          .map((s) => AkSelectedSeatItemModel(
                ssid: s.ssid,
                fuid: s.fuid,
                paxId: s.paxId,
                fare: s.fare,
                tax: s.tax,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'selected_seats':
          selectedSeats.map((s) => (s as AkSelectedSeatItemModel).toJson()).toList(),
    };
  }
}

class AkSelectSeatsModel extends AkSelectSeatsEntity {
  const AkSelectSeatsModel({required super.success});

  factory AkSelectSeatsModel.fromJson(Map<String, dynamic> json) {
    return AkSelectSeatsModel(success: json['success'] ?? false);
  }
}
