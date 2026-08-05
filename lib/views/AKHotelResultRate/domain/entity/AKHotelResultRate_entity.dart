import 'package:equatable/equatable.dart';

class AkHotelResultRateRequestEntity extends Equatable {
  final String searchId;
  final String searchTracingKey;

  const AkHotelResultRateRequestEntity({required this.searchId, required this.searchTracingKey});

  @override
  List<Object?> get props => [searchId, searchTracingKey];
}

class AkHotelRateChargeEntity extends Equatable {
  final double amount;
  final String description;
  final String type;

  const AkHotelRateChargeEntity({required this.amount, required this.description, required this.type});

  @override
  List<Object?> get props => [amount, description, type];
}

class AkHotelRateItemEntity extends Equatable {
  final String id;
  final double total;
  final double baseRate;
  final double ratePerNight;
  final double taxes;
  final String provider;
  final bool isRefundable;
  final bool freeBreakfast;
  final bool freeCancellation;
  final bool payAtHotel;

  const AkHotelRateItemEntity({
    required this.id,
    required this.total,
    required this.baseRate,
    required this.ratePerNight,
    required this.taxes,
    required this.provider,
    required this.isRefundable,
    required this.freeBreakfast,
    required this.freeCancellation,
    required this.payAtHotel,
  });

  @override
  List<Object?> get props => [
        id, total, baseRate, ratePerNight, taxes, provider, isRefundable, freeBreakfast, freeCancellation, payAtHotel,
      ];
}

class AkHotelResultRateEntity extends Equatable {
  /// Raw value from the API — lowercase "inProgress"/"completed", per the
  /// live-verified contract (Benzy's own doc uses different casing and is
  /// wrong). Use [isCompleted] rather than comparing this directly.
  final String searchStatus;
  final String currency;
  final int total;
  final List<AkHotelRateItemEntity> hotels;

  const AkHotelResultRateEntity({
    required this.searchStatus,
    required this.currency,
    required this.total,
    required this.hotels,
  });

  bool get isCompleted => searchStatus.toLowerCase() != 'inprogress';

  @override
  List<Object?> get props => [searchStatus, currency, total, hotels];
}
