import 'package:equatable/equatable.dart';

class AkHotelPriceRequestEntity extends Equatable {
  final String searchId;
  final String hotelId;
  final String priceProvider;
  final String recommendationId;
  final String searchTracingKey;

  const AkHotelPriceRequestEntity({
    required this.searchId,
    required this.hotelId,
    required this.priceProvider,
    required this.recommendationId,
    required this.searchTracingKey,
  });

  @override
  List<Object?> get props => [searchId, hotelId, priceProvider, recommendationId, searchTracingKey];
}

/// The real cancellation charge schedule (richer than Rooms' text-only
/// policy): 0 until [end], then a flat [value]/[valueType] charge.
class AkHotelCancellationRuleEntity extends Equatable {
  final double value;
  final String valueType;
  final double estimatedValue;
  final String start;
  final String end;

  const AkHotelCancellationRuleEntity({
    required this.value,
    required this.valueType,
    required this.estimatedValue,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [value, valueType, estimatedValue, start, end];
}

/// The final, price-checked fare for one room. [roomId] + [id] (roomGroupId)
/// + [providerName] thread into CreateItinerary's Rooms[].
class AkHotelPricedRoomGroupEntity extends Equatable {
  final String id;
  final String providerName;
  final String roomId;
  final double baseRate;
  final double totalRate;
  final int occupancyId;
  final int numOfAdults;
  final List<AkHotelCancellationRuleEntity> cancellationRules;

  const AkHotelPricedRoomGroupEntity({
    required this.id,
    required this.providerName,
    required this.roomId,
    required this.baseRate,
    required this.totalRate,
    required this.occupancyId,
    required this.numOfAdults,
    required this.cancellationRules,
  });

  @override
  List<Object?> get props => [id, providerName, roomId, baseRate, totalRate, occupancyId, numOfAdults, cancellationRules];
}

class AkHotelPriceEntity extends Equatable {
  final String hotelId;
  final String priceId;
  final bool isPotentialSuspect;
  final List<AkHotelPricedRoomGroupEntity> roomGroups;

  const AkHotelPriceEntity({
    required this.hotelId,
    required this.priceId,
    required this.isPotentialSuspect,
    required this.roomGroups,
  });

  @override
  List<Object?> get props => [hotelId, priceId, isPotentialSuspect, roomGroups];
}
