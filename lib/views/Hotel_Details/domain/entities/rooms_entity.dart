import 'package:equatable/equatable.dart';

class RoomEntity extends Equatable {
  final List<String> name;
  final String bookingCode;
  final String inclusion;
  final List<List<Map<String, dynamic>>> dayRates;
  final double totalFare;
  final double totalTax;
  final String? recommendedSellingRate;
  final List<String> roomPromotion;
  final List<Map<String, dynamic>> cancelPolicies;
  final String mealType;
  final bool isRefundable;
  final List<List<Map<String, dynamic>>> supplements;
  final bool withTransfers;

  const RoomEntity({
    required this.name,
    required this.bookingCode,
    required this.inclusion,
    required this.dayRates,
    required this.totalFare,
    required this.totalTax,
    this.recommendedSellingRate,
    required this.roomPromotion,
    required this.cancelPolicies,
    required this.mealType,
    required this.isRefundable,
    required this.supplements,
    required this.withTransfers,
  });

  double get basePrice {
    if (dayRates.isNotEmpty && dayRates.first.isNotEmpty) {
      return dayRates.first.first['BasePrice']?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  String get roomDisplayName {
    if (name.isNotEmpty) {
      return name.first.split(',').first.trim();
    }
    return 'Room';
  }

  String get bedInfo {
    if (name.isNotEmpty && name.first.contains(',')) {
      final parts = name.first.split(',');
      for (var part in parts) {
        if (part.toLowerCase().contains('bed')) {
          return part.trim();
        }
      }
    }
    return 'Bed info not available';
  }

  @override
  List<Object?> get props => [
    name,
    bookingCode,
    inclusion,
    dayRates,
    totalFare,
    totalTax,
    recommendedSellingRate,
    roomPromotion,
    cancelPolicies,
    mealType,
    isRefundable,
    supplements,
    withTransfers,
  ];
}