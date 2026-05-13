import '../../domain/entities/rooms_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.name,
    required super.bookingCode,
    required super.inclusion,
    required super.dayRates,
    required super.totalFare,
    required super.totalTax,
    super.recommendedSellingRate,
    required super.roomPromotion,
    required super.cancelPolicies,
    required super.mealType,
    required super.isRefundable,
    required super.supplements,
    required super.withTransfers,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      name: json['Name'] != null
          ? List<String>.from(json['Name'].map((n) => n.toString()))
          : [],
      bookingCode: json['BookingCode']?.toString() ?? '',
      inclusion: json['Inclusion']?.toString() ?? '',
      dayRates: json['DayRates'] != null
          ? List<List<Map<String, dynamic>>>.from(
          json['DayRates'].map((day) =>
          List<Map<String, dynamic>>.from(
              day.map((rate) => Map<String, dynamic>.from(rate))
          )
          )
      )
          : [],
      totalFare: (json['TotalFare'] ?? 0).toDouble(),
      totalTax: (json['TotalTax'] ?? 0).toDouble(),
      recommendedSellingRate: json['RecommendedSellingRate']?.toString(),
      roomPromotion: json['RoomPromotion'] != null
          ? List<String>.from(json['RoomPromotion'].map((p) => p.toString()))
          : [],
      cancelPolicies: json['CancelPolicies'] != null
          ? List<Map<String, dynamic>>.from(
          json['CancelPolicies'].map((p) => Map<String, dynamic>.from(p))
      )
          : [],
      mealType: json['MealType']?.toString() ?? 'Room_Only',
      isRefundable: json['IsRefundable'] == true,
      supplements: json['Supplements'] != null
          ? List<List<Map<String, dynamic>>>.from(
          json['Supplements'].map((supp) =>
          List<Map<String, dynamic>>.from(
              supp.map((s) => Map<String, dynamic>.from(s))
          )
          )
      )
          : [],
      withTransfers: json['WithTransfers'] == true,
    );
  }
}