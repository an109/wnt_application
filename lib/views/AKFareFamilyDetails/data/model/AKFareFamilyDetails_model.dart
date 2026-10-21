import '../../domain/entity/AKFareFamilyDetails_entity.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkFareFamilyDetailsTripRequestModel
    extends AkFareFamilyDetailsTripRequestEntity {
  const AkFareFamilyDetailsTripRequestModel({
    required super.index,
    required super.amount,
    required super.orderId,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'amount': amount,
        'order_id': orderId,
      };
}

class AkFareFamilyDetailsRequestModel extends AkFareFamilyDetailsRequestEntity {
  const AkFareFamilyDetailsRequestModel({
    required super.tui,
    required super.trips,
    super.tuis,
    super.tripType,
  });

  factory AkFareFamilyDetailsRequestModel.fromEntity(
      AkFareFamilyDetailsRequestEntity entity) {
    return AkFareFamilyDetailsRequestModel(
      tui: entity.tui,
      tuis: entity.tuis,
      tripType: entity.tripType,
      trips: entity.trips
          .map((t) => AkFareFamilyDetailsTripRequestModel(
                index: t.index,
                amount: t.amount,
                orderId: t.orderId,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'search_tui': tui,
        'trip_type': tripType,
        'options': trips
            .map((t) =>
                (t as AkFareFamilyDetailsTripRequestModel).toJson())
            .toList(),
        if (tuis.isNotEmpty) 'tuis': tuis,
      };
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

class AkFareFamilyDetailsModel extends AkFareFamilyDetailsEntity {
  const AkFareFamilyDetailsModel({
    required super.success,
    required super.options,
    required super.raw,
  });

  factory AkFareFamilyDetailsModel.fromJson(Map<String, dynamic> json) {
    return AkFareFamilyDetailsModel(
      success: json['success'] == true,
      options: _parseOptions(json),
      raw: json,
    );
  }

  /// Parses fare family options defensively.
  ///
  /// Walks the response in priority order:
  ///
  /// 1. `details.<index>.{baggage:{checkin,cabin}, fare_rule}`
  ///    — the WanderNova `/akbar/FareFamilyDetails/` endpoint response shape.
  ///    This is the primary path; it carries real baggage + fare-rule data.
  /// 2. `Trips[].Journey[].{Index, FareFamilyName, NetFare, Refundable}`
  ///    — legacy Akbar nested structure (kept as a fallback).
  /// 3. `FareFamilies[].{Index, Name, ...}` — flat legacy fallback.
  ///
  /// If none yields data the options map comes back empty and the
  /// UI falls back to rank-based "Saver / Standard / Flexi" labels.
  static Map<String, AkFareFamilyOptionEntity> _parseOptions(
      Map<String, dynamic> json) {
    final options = <String, AkFareFamilyOptionEntity>{};

    // Path 1: actual backend response — details.<index>.{baggage, fare_rule}
    final detailsMap = json['details'];
    if (detailsMap is Map) {
      detailsMap.forEach((rawIndex, rawValue) {
        if (rawValue is! Map<String, dynamic>) return;
        final index = rawIndex.toString();
        final baggage = rawValue['baggage'];
        final checkin = (baggage is Map) ? baggage['checkin']?.toString() : null;
        final cabin   = (baggage is Map) ? baggage['cabin']?.toString()   : null;
        final fareRule = rawValue['fare_rule'];
        // Merge into an existing entry (from legacy paths) or create a stub.
        // amount/refundable/label come from the GetExpSearch response stored
        // in FlightEntity.fareFamilyOptions — the FareFamilyDetails endpoint
        // only adds baggage + fare_rule on top.
        final existing = options[index];
        options[index] = AkFareFamilyOptionEntity(
          index: index,
          label: existing?.label,
          amount: existing?.amount ?? 0,
          refundable: existing?.refundable ?? false,
          checkin: checkin,
          cabin: cabin,
          fareRule: fareRule,
        );
      });
    }

    // Path 2: Trips[].Journey[] (legacy / alternative Akbar response shape)
    final tripsList = json['Trips'];
    if (tripsList is List) {
      for (final trip in tripsList) {
        if (trip is! Map<String, dynamic>) continue;
        final journeyList = trip['Journey'];
        if (journeyList is! List) continue;
        for (final journey in journeyList) {
          if (journey is! Map<String, dynamic>) continue;
          final option = _optionFromJourney(journey);
          if (option == null) continue;
          // Merge: keep baggage/fareRule from Path 1 if already set.
          final existing = options[option.index];
          options[option.index] = AkFareFamilyOptionEntity(
            index: option.index,
            label: option.label,
            amount: option.amount,
            refundable: option.refundable,
            checkin: existing?.checkin ?? option.checkin,
            cabin: existing?.cabin ?? option.cabin,
            fareRule: existing?.fareRule ?? option.fareRule,
          );
        }
      }
    }

    // Path 3: flat FareFamilies[]
    final familiesList = json['FareFamilies'] ?? json['fare_families'];
    if (familiesList is List) {
      for (final family in familiesList) {
        if (family is! Map<String, dynamic>) continue;
        final option = _optionFromFamily(family);
        if (option == null) continue;
        final existing = options[option.index];
        options[option.index] = AkFareFamilyOptionEntity(
          index: option.index,
          label: option.label,
          amount: option.amount,
          refundable: option.refundable,
          checkin: existing?.checkin ?? option.checkin,
          cabin: existing?.cabin ?? option.cabin,
          fareRule: existing?.fareRule ?? option.fareRule,
        );
      }
    }

    return options;
  }

  static AkFareFamilyOptionEntity? _optionFromJourney(
      Map<String, dynamic> j) {
    final index = j['Index']?.toString() ??
        j['ResultIndex']?.toString() ??
        j['index']?.toString();
    if (index == null || index.isEmpty) return null;

    final label = _firstNonEmpty([
      j['FareFamilyName'],
      j['FamilyName'],
      j['FareFamily'],
      j['FareClassName'],
      j['Name'],
    ]);

    final amount = _toDouble(j['GrossFare'] ?? j['Amount'] ?? 0);
    final refundable =
        (j['Refundable']?.toString().toUpperCase() ?? '') == 'Y';

    return AkFareFamilyOptionEntity(
      index: index,
      label: label,
      amount: amount,
      refundable: refundable,
    );
  }

  static AkFareFamilyOptionEntity? _optionFromFamily(
      Map<String, dynamic> f) {
    final index = f['Index']?.toString() ??
        f['ResultIndex']?.toString() ??
        f['index']?.toString();
    if (index == null || index.isEmpty) return null;

    final label = _firstNonEmpty([
      f['FareFamilyName'],
      f['FamilyName'],
      f['Name'],
      f['name'],
    ]);

    final amount = _toDouble(f['GrossFare'] ?? f['Amount'] ?? f['amount'] ?? 0);
    final refundable =
        (f['Refundable']?.toString().toUpperCase() ?? '') == 'Y';

    return AkFareFamilyOptionEntity(
      index: index,
      label: label,
      amount: amount,
      refundable: refundable,
    );
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
