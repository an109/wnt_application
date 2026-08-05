import '../../domain/entity/AKHotelResultRate_entity.dart';

class AkHotelRateItemModel extends AkHotelRateItemEntity {
  const AkHotelRateItemModel({
    required super.id,
    required super.total,
    required super.baseRate,
    required super.ratePerNight,
    required super.taxes,
    required super.provider,
    required super.isRefundable,
    required super.freeBreakfast,
    required super.freeCancellation,
    required super.payAtHotel,
  });

  factory AkHotelRateItemModel.fromJson(Map<String, dynamic> json) {
    final rate = json['rate'] as Map<String, dynamic>? ?? {};
    final rawTaxes = rate['taxes'];
    double taxesTotal = 0;
    if (rawTaxes is num) {
      taxesTotal = rawTaxes.toDouble();
    } else if (rawTaxes is List) {
      taxesTotal = rawTaxes.fold<double>(0, (s, t) => s + ((t is Map ? t['amount'] : null) as num? ?? 0).toDouble());
    }
    return AkHotelRateItemModel(
      id: json['id']?.toString() ?? '',
      total: (rate['total'] as num?)?.toDouble() ?? 0.0,
      baseRate: (rate['baseRate'] as num?)?.toDouble() ?? 0.0,
      ratePerNight: (rate['ratePerNight'] as num?)?.toDouble() ?? 0.0,
      taxes: taxesTotal,
      provider: rate['provider']?.toString() ?? '',
      isRefundable: json['isRefundable'] == true,
      freeBreakfast: json['freeBreakfast'] == true,
      freeCancellation: json['freeCancellation'] == true,
      payAtHotel: json['payAtHotel'] == true,
    );
  }
}

class AkHotelResultRateModel extends AkHotelResultRateEntity {
  const AkHotelResultRateModel({
    required super.searchStatus,
    required super.currency,
    required super.total,
    required super.hotels,
  });

  factory AkHotelResultRateModel.fromJson(Map<String, dynamic> json) {
    final rawHotels = json['hotels'] as List<dynamic>? ?? [];
    return AkHotelResultRateModel(
      searchStatus: json['searchStatus']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'INR',
      total: (json['total'] as num?)?.toInt() ?? 0,
      hotels: rawHotels.whereType<Map<String, dynamic>>().map(AkHotelRateItemModel.fromJson).toList(),
    );
  }
}
