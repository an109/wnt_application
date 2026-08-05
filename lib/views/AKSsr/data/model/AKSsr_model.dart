import '../../domain/entity/AKSsr_entity.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkSsrRequestModel extends AkSsrRequestEntity {
  const AkSsrRequestModel({required super.tui, super.afterPricing, super.orderIds});

  factory AkSsrRequestModel.fromEntity(AkSsrRequestEntity entity) {
    return AkSsrRequestModel(
      tui: entity.tui,
      afterPricing: entity.afterPricing,
      orderIds: entity.orderIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tui': tui,
      'after_pricing': afterPricing,
      'trips': orderIds.map((id) => {'order_id': id}).toList(),
    };
  }
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

double _toD(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
int _toI(dynamic v) => (v is int) ? v : int.tryParse(v?.toString() ?? '') ?? 0;
bool _toB(dynamic v) => v == true || v == 1 || v?.toString().toLowerCase() == 'true';

/// The API doc only shows PascalCase keys, but doesn't guarantee that's the
/// exact casing the live endpoint uses — this tries every common variant
/// (PascalCase, camelCase, snake_case, lowercase) so a real response doesn't
/// silently parse into an empty list just because of a casing mismatch.
dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

class AkSsrItemModel extends AkSsrItemEntity {
  const AkSsrItemModel({
    required super.id,
    required super.code,
    required super.description,
    required super.charge,
    required super.typeName,
    required super.isFree,
  });

  factory AkSsrItemModel.fromJson(Map<String, dynamic> json) {
    return AkSsrItemModel(
      id: _toI(_pick(json, const ['ID', 'Id', 'id'])),
      code: _pick(json, const ['Code', 'code'])?.toString() ?? '',
      description: _pick(json, const ['Description', 'description', 'Desc', 'Name', 'name'])
              ?.toString() ??
          '',
      charge: _toD(_pick(json, const ['Charge', 'charge', 'Amount', 'amount', 'Price', 'price'])),
      typeName: _pick(json, const ['TypeName', 'typeName', 'type_name', 'Type', 'type'])
              ?.toString() ??
          '',
      isFree: _toB(_pick(json, const ['IsFree', 'isFree', 'is_free', 'Free', 'free'])),
    );
  }
}

class AkSsrSegmentModel extends AkSsrSegmentEntity {
  const AkSsrSegmentModel({required super.fuid, required super.items});

  factory AkSsrSegmentModel.fromJson(Map<String, dynamic> json) {
    final ssrList = _pick(json, const ['SSR', 'ssr', 'Ssr', 'Items', 'items']) as List? ?? [];
    return AkSsrSegmentModel(
      fuid: _toI(_pick(json, const ['FUID', 'Fuid', 'fuid'])),
      items: ssrList
          .whereType<Map<String, dynamic>>()
          .map((i) => AkSsrItemModel.fromJson(i))
          .toList(),
    );
  }
}

class AkSsrJourneyModel extends AkSsrJourneyEntity {
  const AkSsrJourneyModel({
    required super.multiSelectAllowed,
    required super.segments,
  });

  factory AkSsrJourneyModel.fromJson(Map<String, dynamic> json) {
    final segmentsList =
        _pick(json, const ['Segments', 'segments']) as List? ?? [];
    return AkSsrJourneyModel(
      multiSelectAllowed: _toB(_pick(
          json, const ['MultiSelectAllowed', 'multiSelectAllowed', 'multi_select_allowed'])),
      segments: segmentsList
          .whereType<Map<String, dynamic>>()
          .map((s) => AkSsrSegmentModel.fromJson(s))
          .toList(),
    );
  }
}

class AkSsrTripModel extends AkSsrTripEntity {
  const AkSsrTripModel({required super.journey});

  factory AkSsrTripModel.fromJson(Map<String, dynamic> json) {
    final journeyList = _pick(json, const ['Journey', 'journey']) as List? ?? [];
    return AkSsrTripModel(
      journey: journeyList
          .whereType<Map<String, dynamic>>()
          .map((j) => AkSsrJourneyModel.fromJson(j))
          .toList(),
    );
  }
}

class AkSsrModel extends AkSsrEntity {
  const AkSsrModel({
    required super.success,
    required super.tui,
    required super.trips,
  });

  factory AkSsrModel.fromJson(Map<String, dynamic> json) {
    final tripsList = _pick(json, const ['Trips', 'trips']) as List? ?? [];
    return AkSsrModel(
      success: _toB(_pick(json, const ['success', 'Success'])),
      tui: _pick(json, const ['tui', 'TUI', 'Tui'])?.toString() ?? '',
      trips: tripsList
          .whereType<Map<String, dynamic>>()
          .map((t) => AkSsrTripModel.fromJson(t))
          .toList(),
    );
  }
}
