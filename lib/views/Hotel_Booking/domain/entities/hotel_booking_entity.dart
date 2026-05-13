import 'package:equatable/equatable.dart';

class HotelBookingEntity extends Equatable {
  final StatusEntity status;
  final List<HotelResultEntity> hotelResult;

  const HotelBookingEntity({
    required this.status,
    required this.hotelResult,
  });

  @override
  List<Object?> get props => [status, hotelResult];
}

class StatusEntity extends Equatable {
  final int code;
  final String description;

  const StatusEntity({
    required this.code,
    required this.description,
  });

  @override
  List<Object?> get props => [code, description];
}

class HotelResultEntity extends Equatable {
  final String hotelCode;
  final String currency;
  final List<RoomEntity> rooms;
  final List<String> rateConditions;

  const HotelResultEntity({
    required this.hotelCode,
    required this.currency,
    required this.rooms,
    required this.rateConditions,
  });

  @override
  List<Object?> get props => [hotelCode, currency, rooms, rateConditions];
}

class RoomEntity extends Equatable {
  final List<String> name;
  final String bookingCode;
  final String inclusion;
  final double totalFare;
  final double totalTax;
  final String recommendedSellingRate;
  final List<String> roomPromotion;
  final List<CancelPolicyEntity> cancelPolicies;
  final String mealType;
  final bool isRefundable;
  final List<String> amenities;

  const RoomEntity({
    required this.name,
    required this.bookingCode,
    required this.inclusion,
    required this.totalFare,
    required this.totalTax,
    required this.recommendedSellingRate,
    required this.roomPromotion,
    required this.cancelPolicies,
    required this.mealType,
    required this.isRefundable,
    required this.amenities,
  });

  @override
  List<Object?> get props => [
    name,
    bookingCode,
    inclusion,
    totalFare,
    totalTax,
    recommendedSellingRate,
    roomPromotion,
    cancelPolicies,
    mealType,
    isRefundable,
    amenities,
  ];
}

class CancelPolicyEntity extends Equatable {
  final String fromDate;
  final String chargeType;
  final double cancellationCharge;

  const CancelPolicyEntity({
    required this.fromDate,
    required this.chargeType,
    required this.cancellationCharge,
  });

  @override
  List<Object?> get props => [fromDate, chargeType, cancellationCharge];
}