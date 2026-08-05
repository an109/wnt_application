import '../../domain/entity/AKTravelCheckList_entity.dart';

class AkTravelCheckListRequestModel extends AkTravelCheckListRequestEntity {
  const AkTravelCheckListRequestModel({required super.tui});

  factory AkTravelCheckListRequestModel.fromEntity(AkTravelCheckListRequestEntity entity) {
    return AkTravelCheckListRequestModel(tui: entity.tui);
  }

  Map<String, dynamic> toJson() {
    return {
      'tui': tui,
    };
  }
}

class AkTravellerCheckListModel extends AkTravellerCheckListEntity {
  const AkTravellerCheckListModel({
    required super.dob,
    required super.passportNo,
    required super.nationality,
    required super.visaType,
    required super.pdoe,
    required super.pdoi,
    required super.pli,
    required super.panNo,
    required super.emigCheck,
  });

  static bool _flag(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  factory AkTravellerCheckListModel.fromJson(Map<String, dynamic> json) {
    return AkTravellerCheckListModel(
      dob: _flag(json['DOB']),
      passportNo: _flag(json['PassportNo']),
      nationality: _flag(json['Nationality']),
      visaType: _flag(json['VisaType']),
      pdoe: _flag(json['PDOE']),
      pdoi: _flag(json['PDOI']),
      pli: _flag(json['PLI']),
      panNo: _flag(json['PANNo']),
      emigCheck: _flag(json['EmigCheck']),
    );
  }
}

class AkFnuLnuSettingModel extends AkFnuLnuSettingEntity {
  const AkFnuLnuSettingModel({
    required super.airlineCode,
    required super.titleMandatory,
  });

  factory AkFnuLnuSettingModel.fromJson(Map<String, dynamic> json) {
    return AkFnuLnuSettingModel(
      airlineCode: json['AirlineCode']?.toString() ?? '',
      titleMandatory: json['TitleMandatory'] == true,
    );
  }
}

class AkTravelCheckListModel extends AkTravelCheckListEntity {
  const AkTravelCheckListModel({
    required super.success,
    required super.unavailable,
    required super.travellerCheckList,
    required super.fnuLnuSettings,
  });

  factory AkTravelCheckListModel.fromJson(Map<String, dynamic> json) {
    final checklistJson = json['TravellerCheckList'] as List? ?? [];
    final fnuLnuJson = json['FnuLnuSettings'] as List? ?? [];
    return AkTravelCheckListModel(
      success: json['success'] ?? false,
      unavailable: false,
      travellerCheckList: checklistJson
          .whereType<Map<String, dynamic>>()
          .map((e) => AkTravellerCheckListModel.fromJson(e))
          .toList(),
      fnuLnuSettings: fnuLnuJson
          .whereType<Map<String, dynamic>>()
          .map((e) => AkFnuLnuSettingModel.fromJson(e))
          .toList(),
    );
  }

  /// Returned when the backend answers with the raw string
  /// "invalid Pricing TUI" instead of JSON — see [AkTravelCheckListEntity.unavailable].
  factory AkTravelCheckListModel.unavailable() {
    return const AkTravelCheckListModel(
      success: false,
      unavailable: true,
      travellerCheckList: [],
      fnuLnuSettings: [],
    );
  }
}
