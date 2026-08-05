import '../../domain/entity/AKSelectSsr_entity.dart';

class AkSelectedSsrItemModel extends AkSelectedSsrItemEntity {
  const AkSelectedSsrItemModel({
    required super.id,
    required super.fuid,
    required super.paxId,
    required super.charge,
    super.vat,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fuid': fuid,
      'pax_id': paxId,
      'charge': charge,
      'vat': vat,
    };
  }
}

class AkSelectSsrRequestModel extends AkSelectSsrRequestEntity {
  const AkSelectSsrRequestModel({
    required super.sessionId,
    required super.selectedSsr,
  });

  factory AkSelectSsrRequestModel.fromEntity(AkSelectSsrRequestEntity entity) {
    return AkSelectSsrRequestModel(
      sessionId: entity.sessionId,
      selectedSsr: entity.selectedSsr
          .map((s) => AkSelectedSsrItemModel(
                id: s.id,
                fuid: s.fuid,
                paxId: s.paxId,
                charge: s.charge,
                vat: s.vat,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'selected_ssr':
          selectedSsr.map((s) => (s as AkSelectedSsrItemModel).toJson()).toList(),
    };
  }
}

class AkSelectSsrModel extends AkSelectSsrEntity {
  const AkSelectSsrModel({required super.success});

  factory AkSelectSsrModel.fromJson(Map<String, dynamic> json) {
    return AkSelectSsrModel(success: json['success'] ?? false);
  }
}
