import '../../domain/entity/AKSeatLayout_entity.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkSeatLayoutRequestModel extends AkSeatLayoutRequestEntity {
  const AkSeatLayoutRequestModel({required super.tui, super.orderIds});

  factory AkSeatLayoutRequestModel.fromEntity(AkSeatLayoutRequestEntity entity) {
    return AkSeatLayoutRequestModel(tui: entity.tui, orderIds: entity.orderIds);
  }

  Map<String, dynamic> toJson() {
    return {
      'tui': tui,
      'trips': orderIds.map((id) => {'order_id': id}).toList(),
    };
  }
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

double _toD(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
int _toI(dynamic v) => (v is int) ? v : int.tryParse(v?.toString() ?? '') ?? 0;
bool _toB(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  return v == true || v == 1 || v.toString().toLowerCase() == 'true';
}

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

class AkSeatModel extends AkSeatEntity {
  const AkSeatModel({
    required super.seatNumber,
    required super.ssid,
    required super.fare,
    required super.tax,
    required super.selectable,
    required super.isEmergencyExit,
    required super.seatTypeName,
    required super.xValue,
    required super.yValue,
  });

  factory AkSeatModel.fromJson(Map<String, dynamic> json) {
    return AkSeatModel(
      seatNumber:
          _pick(json, const ['SeatNumber', 'seatNumber', 'seat_number'])?.toString() ?? '',
      ssid: _toI(_pick(json, const ['SSID', 'Ssid', 'ssid'])),
      fare: _toD(_pick(json, const ['Fare', 'fare'])),
      tax: _toD(_pick(json, const ['Tax', 'tax'])),
      selectable: _toB(_pick(json, const ['Selectable', 'selectable'])),
      isEmergencyExit:
          _toB(_pick(json, const ['IsEmergencyExit', 'isEmergencyExit', 'is_emergency_exit'])),
      seatTypeName:
          _pick(json, const ['SeatTypeName', 'seatTypeName', 'seat_type_name', 'SeatType'])
                  ?.toString() ??
              '',
      xValue: _pick(json, const ['XValue', 'xValue', 'x_value', 'X'])?.toString() ?? '0',
      yValue: _pick(json, const ['YValue', 'yValue', 'y_value', 'Y'])?.toString() ?? '0',
    );
  }
}

class AkSeatLayoutSegmentModel extends AkSeatLayoutSegmentEntity {
  const AkSeatLayoutSegmentModel({
    required super.fuid,
    required super.flightNo,
    required super.seats,
  });

  factory AkSeatLayoutSegmentModel.fromJson(Map<String, dynamic> json) {
    final seatsList = _pick(json, const ['Seats', 'seats']) as List? ?? [];
    return AkSeatLayoutSegmentModel(
      fuid: _toI(_pick(json, const ['FUID', 'Fuid', 'fuid'])),
      flightNo: _pick(json, const ['FlightNo', 'flightNo', 'flight_no'])?.toString() ?? '',
      seats: seatsList
          .whereType<Map<String, dynamic>>()
          .map((s) => AkSeatModel.fromJson(s))
          .toList(),
    );
  }
}

class AkSeatLayoutJourneyModel extends AkSeatLayoutJourneyEntity {
  const AkSeatLayoutJourneyModel({required super.segments});

  factory AkSeatLayoutJourneyModel.fromJson(Map<String, dynamic> json) {
    final segmentsList = _pick(json, const ['Segments', 'segments']) as List? ?? [];
    return AkSeatLayoutJourneyModel(
      segments: segmentsList
          .whereType<Map<String, dynamic>>()
          .map((s) => AkSeatLayoutSegmentModel.fromJson(s))
          .toList(),
    );
  }
}

class AkSeatLayoutTripModel extends AkSeatLayoutTripEntity {
  const AkSeatLayoutTripModel({required super.journey});

  factory AkSeatLayoutTripModel.fromJson(Map<String, dynamic> json) {
    final journeyList = _pick(json, const ['Journey', 'journey']) as List? ?? [];
    return AkSeatLayoutTripModel(
      journey: journeyList
          .whereType<Map<String, dynamic>>()
          .map((j) => AkSeatLayoutJourneyModel.fromJson(j))
          .toList(),
    );
  }
}

class AkSeatLayoutModel extends AkSeatLayoutEntity {
  const AkSeatLayoutModel({
    required super.success,
    required super.supported,
    required super.trips,
  });

  factory AkSeatLayoutModel.fromJson(Map<String, dynamic> json) {
    final tripsList = _pick(json, const ['Trips', 'trips']) as List? ?? [];
    return AkSeatLayoutModel(
      success: _toB(_pick(json, const ['success', 'Success'])),
      supported: _toB(_pick(json, const ['supported', 'Supported']), fallback: true),
      trips: tripsList
          .whereType<Map<String, dynamic>>()
          .map((t) => AkSeatLayoutTripModel.fromJson(t))
          .toList(),
    );
  }
}
