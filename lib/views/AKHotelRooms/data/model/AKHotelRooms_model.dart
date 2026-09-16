import '../../domain/entity/AKHotelRooms_entity.dart';

AkHotelOccupancyEntity _parseOccupancy(Map<String, dynamic> json) {
  final rawAges = json['childAges'] as List<dynamic>? ?? [];
  return AkHotelOccupancyEntity(
    occupancyId: (json['occupancyId'] as num?)?.toInt() ?? 1,
    numOfAdults: (json['numOfAdults'] as num?)?.toInt() ?? 1,
    numOfChildren: (json['numOfChildren'] as num?)?.toInt() ?? 0,
    childAges: rawAges.map((a) => (a as num).toInt()).toList(),
  );
}

List<AkHotelChargeEntity> _parseTaxes(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((t) => AkHotelChargeEntity(
            amount: (t['amount'] as num?)?.toDouble() ?? 0.0,
            description: t['description']?.toString() ?? '',
          ))
      .toList();
}

List<String> _parseRoomImages(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => e is String ? e : (e is Map ? (e['url'] ?? '').toString() : ''))
      .where((s) => s.isNotEmpty)
      .toList();
}

int? _toInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}

double? _toDouble(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

/// `room.beds` — shape isn't confirmed by any populated sample seen so far
/// (every hotel checked has it empty/null), so this accepts whichever
/// shape the vendor turns out to send: plain strings, or objects carrying
/// a `type`/`name`/`bedType` key.
List<String> _parseBedTypes(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) {
        if (e is String) return e;
        if (e is Map) return (e['type'] ?? e['name'] ?? e['bedType'] ?? '').toString();
        return '';
      })
      .where((s) => s.isNotEmpty)
      .toList();
}

/// `room.facilities` — same `{id, groupId, name}` shape the hotel-level
/// Content facilities use.
List<String> _parseRoomFacilities(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((f) => (f['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
}

/// `room.views` — not confirmed whether the vendor ever sends a list
/// instead of a single string, so both are accepted; a list is joined.
String? _parseView(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return raw.isEmpty ? null : raw;
  if (raw is List) {
    final joined = raw.map((e) => e.toString()).where((s) => s.isNotEmpty).join(', ');
    return joined.isEmpty ? null : joined;
  }
  return null;
}

List<String> _parseCancellationTexts(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((p) => (p['text'] ?? '').toString())
      .where((t) => t.isNotEmpty)
      .toList();
}

class AkHotelRoomGroupModel extends AkHotelRoomGroupEntity {
  const AkHotelRoomGroupModel({
    required super.id,
    required super.providerName,
    required super.needsPriceCheck,
    required super.availability,
    required super.roomId,
    required super.roomName,
    required super.description,
    required super.images,
    required super.occupancies,
    required super.roomCount,
    required super.baseRate,
    required super.totalRate,
    required super.taxes,
    required super.refundable,
    required super.boardBasisDescription,
    required super.cancellationPolicyTexts,
    super.maxGuestAllowed,
    super.maxAdultAllowed,
    super.maxChildrenAllowed,
    super.area,
    super.bedTypes,
    super.roomFacilities,
    super.view,
    super.smokingAllowed,
  });

  factory AkHotelRoomGroupModel.fromJson(Map<String, dynamic> json) {
    final room = json['room'] as Map<String, dynamic>? ?? {};
    final boardBasis = json['boardBasis'] as Map<String, dynamic>?;
    final rawOccupancies = json['occupancies'] as List<dynamic>? ?? [];
    return AkHotelRoomGroupModel(
      id: json['id']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? '',
      needsPriceCheck: json['needsPriceCheck'] == true,
      availability: (json['availability'] as num?)?.toInt() ?? 0,
      roomId: room['id']?.toString() ?? '',
      roomName: room['name']?.toString() ?? room['standardRoomName']?.toString() ?? '',
      description: room['description']?.toString() ?? '',
      images: _parseRoomImages(room['images']),
      occupancies: rawOccupancies.whereType<Map<String, dynamic>>().map(_parseOccupancy).toList(),
      roomCount: (json['roomCount'] as num?)?.toInt() ?? rawOccupancies.length,
      baseRate: (json['baseRate'] as num?)?.toDouble() ?? 0.0,
      totalRate: (json['totalRate'] as num?)?.toDouble() ?? 0.0,
      taxes: _parseTaxes(json['taxes']),
      refundable: json['refundable'] == true,
      boardBasisDescription: boardBasis?['description']?.toString() ?? '',
      cancellationPolicyTexts: _parseCancellationTexts(json['cancellationPolicies']),
      maxGuestAllowed: _toInt(room['maxGuestAllowed']),
      maxAdultAllowed: _toInt(room['maxAdultAllowed']),
      maxChildrenAllowed: _toInt(room['maxChildrenAllowed']),
      area: _toDouble(room['area']),
      bedTypes: _parseBedTypes(room['beds']),
      roomFacilities: _parseRoomFacilities(room['facilities']),
      view: _parseView(room['views']),
      smokingAllowed: room['smokingAllowed'] is bool ? room['smokingAllowed'] as bool : null,
    );
  }
}

class AkHotelRecommendationModel extends AkHotelRecommendationEntity {
  const AkHotelRecommendationModel({required super.id, required super.total, required super.roomGroups});

  factory AkHotelRecommendationModel.fromJson(Map<String, dynamic> json) {
    final rawRoomGroups = json['roomGroup'] as List<dynamic>? ?? [];
    return AkHotelRecommendationModel(
      id: json['id']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      roomGroups: rawRoomGroups.whereType<Map<String, dynamic>>().map(AkHotelRoomGroupModel.fromJson).toList(),
    );
  }
}

class AkHotelRoomsResultModel extends AkHotelRoomsResultEntity {
  const AkHotelRoomsResultModel({required super.recommendations});

  factory AkHotelRoomsResultModel.fromJson(Map<String, dynamic> json) {
    final rawRecommendations = json['recommendations'] as List<dynamic>? ?? [];
    return AkHotelRoomsResultModel(
      recommendations:
          rawRecommendations.whereType<Map<String, dynamic>>().map(AkHotelRecommendationModel.fromJson).toList(),
    );
  }
}
