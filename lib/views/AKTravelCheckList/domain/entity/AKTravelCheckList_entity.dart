import 'package:equatable/equatable.dart';

class AkTravelCheckListRequestEntity extends Equatable {
  // The pricing tui (from SmartPricer/GetSPricer) — must be called AFTER
  // GetSPricer has resolved for this tui, or the backend answers with the
  // string "invalid Pricing TUI" instead of a checklist.
  final String tui;

  const AkTravelCheckListRequestEntity({required this.tui});

  @override
  List<Object?> get props => [tui];
}

class AkTravellerCheckListEntity extends Equatable {
  final bool dob;
  final bool passportNo;
  final bool nationality;
  final bool visaType;
  final bool pdoe;
  final bool pdoi;
  final bool pli;
  final bool panNo;
  final bool emigCheck;

  const AkTravellerCheckListEntity({
    required this.dob,
    required this.passportNo,
    required this.nationality,
    required this.visaType,
    required this.pdoe,
    required this.pdoi,
    required this.pli,
    required this.panNo,
    required this.emigCheck,
  });

  @override
  List<Object?> get props => [
    dob, passportNo, nationality, visaType, pdoe, pdoi, pli, panNo, emigCheck,
  ];
}

class AkFnuLnuSettingEntity extends Equatable {
  final String airlineCode;
  final bool titleMandatory;

  const AkFnuLnuSettingEntity({
    required this.airlineCode,
    required this.titleMandatory,
  });

  @override
  List<Object?> get props => [airlineCode, titleMandatory];
}

class AkTravelCheckListEntity extends Equatable {
  final bool success;
  // True when the backend answered with the raw string "invalid Pricing
  // TUI" instead of a real checklist (i.e. called before GetSPricer
  // resolved for this tui) — callers must NOT treat this as "nothing is
  // mandatory" and should fall back to conservative requirements instead.
  final bool unavailable;
  final List<AkTravellerCheckListEntity> travellerCheckList;
  final List<AkFnuLnuSettingEntity> fnuLnuSettings;

  const AkTravelCheckListEntity({
    required this.success,
    required this.unavailable,
    required this.travellerCheckList,
    required this.fnuLnuSettings,
  });

  @override
  List<Object?> get props => [success, unavailable, travellerCheckList, fnuLnuSettings];
}
