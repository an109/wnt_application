import '../../domain/entity/AKHotelPrice_entity.dart';

List<AkHotelCancellationRuleEntity> _parseRules(Map<String, dynamic> roomGroupJson) {
  final policies = roomGroupJson['cancellationPolicies'] as List<dynamic>? ?? [];
  final rules = <AkHotelCancellationRuleEntity>[];
  for (final policy in policies.whereType<Map>()) {
    final rawRules = policy['rules'] as List<dynamic>? ?? [];
    for (final rule in rawRules.whereType<Map>()) {
      rules.add(AkHotelCancellationRuleEntity(
        value: (rule['value'] as num?)?.toDouble() ?? 0.0,
        valueType: (rule['valueType'] ?? '').toString(),
        estimatedValue: (rule['estimatedValue'] as num?)?.toDouble() ?? 0.0,
        start: (rule['start'] ?? '').toString(),
        end: (rule['end'] ?? '').toString(),
      ));
    }
  }
  return rules;
}

class AkHotelPricedRoomGroupModel extends AkHotelPricedRoomGroupEntity {
  const AkHotelPricedRoomGroupModel({
    required super.id,
    required super.providerName,
    required super.roomId,
    required super.baseRate,
    required super.totalRate,
    required super.occupancyId,
    required super.numOfAdults,
    required super.cancellationRules,
  });

  factory AkHotelPricedRoomGroupModel.fromJson(Map<String, dynamic> json) {
    final room = json['room'] as Map<String, dynamic>? ?? {};
    final occupancies = json['occupancies'] as List<dynamic>? ?? [];
    final firstOccupancy = occupancies.isNotEmpty && occupancies.first is Map
        ? occupancies.first as Map<String, dynamic>
        : <String, dynamic>{};
    return AkHotelPricedRoomGroupModel(
      id: json['id']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? '',
      roomId: room['id']?.toString() ?? '',
      baseRate: (json['baseRate'] as num?)?.toDouble() ?? 0.0,
      totalRate: (json['totalRate'] as num?)?.toDouble() ?? 0.0,
      occupancyId: (firstOccupancy['occupancyId'] as num?)?.toInt() ?? 1,
      numOfAdults: (firstOccupancy['numOfAdults'] as num?)?.toInt() ?? 1,
      cancellationRules: _parseRules(json),
    );
  }
}

class AkHotelPriceModel extends AkHotelPriceEntity {
  const AkHotelPriceModel({
    required super.hotelId,
    required super.priceId,
    required super.isPotentialSuspect,
    required super.roomGroups,
  });

  factory AkHotelPriceModel.fromJson(Map<String, dynamic> json) {
    final rawRoomGroups = json['roomGroup'] as List<dynamic>? ?? [];
    return AkHotelPriceModel(
      hotelId: json['hotelId']?.toString() ?? '',
      priceId: json['priceId']?.toString() ?? '',
      isPotentialSuspect: json['isPotentialSuspect'] == true,
      roomGroups: rawRoomGroups.whereType<Map<String, dynamic>>().map(AkHotelPricedRoomGroupModel.fromJson).toList(),
    );
  }
}
