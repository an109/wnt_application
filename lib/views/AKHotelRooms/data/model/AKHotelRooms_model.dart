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
    required super.occupancies,
    required super.roomCount,
    required super.baseRate,
    required super.totalRate,
    required super.taxes,
    required super.refundable,
    required super.boardBasisDescription,
    required super.cancellationPolicyTexts,
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
      occupancies: rawOccupancies.whereType<Map<String, dynamic>>().map(_parseOccupancy).toList(),
      roomCount: (json['roomCount'] as num?)?.toInt() ?? rawOccupancies.length,
      baseRate: (json['baseRate'] as num?)?.toDouble() ?? 0.0,
      totalRate: (json['totalRate'] as num?)?.toDouble() ?? 0.0,
      taxes: _parseTaxes(json['taxes']),
      refundable: json['refundable'] == true,
      boardBasisDescription: boardBasis?['description']?.toString() ?? '',
      cancellationPolicyTexts: _parseCancellationTexts(json['cancellationPolicies']),
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
