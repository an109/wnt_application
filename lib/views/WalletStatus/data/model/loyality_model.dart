
import '../../domain/entity/loyality_entity.dart';

class LoyaltyModel extends LoyaltyEntity {
  const LoyaltyModel({
    required bool success,
    required String tier,
    required String tierLabel,
    required String tierColor,
    required int completedBookings,
    required List<String> benefits,
    String? nextTier,
    String? nextTierLabel,
    int? bookingsNeeded,
  }) : super(
    success: success,
    tier: tier,
    tierLabel: tierLabel,
    tierColor: tierColor,
    completedBookings: completedBookings,
    benefits: benefits,
    nextTier: nextTier,
    nextTierLabel: nextTierLabel,
    bookingsNeeded: bookingsNeeded,
  );

  factory LoyaltyModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyModel(
      success: json['success'] ?? false,
      tier: json['tier'] ?? '',
      tierLabel: json['tier_label'] ?? '',
      tierColor: json['tier_color'] ?? '',
      completedBookings: json['completed_bookings'] ?? 0,
      benefits: List<String>.from(json['benefits'] ?? []),
      nextTier: json['next_tier'],
      nextTierLabel: json['next_tier_label'],
      bookingsNeeded: json['bookings_needed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'tier': tier,
      'tier_label': tierLabel,
      'tier_color': tierColor,
      'completed_bookings': completedBookings,
      'benefits': benefits,
      'next_tier': nextTier,
      'next_tier_label': nextTierLabel,
      'bookings_needed': bookingsNeeded,
    };
  }
}