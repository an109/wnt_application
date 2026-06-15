import 'package:equatable/equatable.dart';

class LoyaltyEntity extends Equatable {
  final bool success;
  final String tier;
  final String tierLabel;
  final String tierColor;
  final int completedBookings;
  final List<String> benefits;
  final String? nextTier;
  final String? nextTierLabel;
  final int? bookingsNeeded;

  const LoyaltyEntity({
    required this.success,
    required this.tier,
    required this.tierLabel,
    required this.tierColor,
    required this.completedBookings,
    required this.benefits,
    this.nextTier,
    this.nextTierLabel,
    this.bookingsNeeded,
  });

  // Calculate progress percentage based on your formula
  double get progressPercentage {
    if (bookingsNeeded == null || bookingsNeeded == 0) return 1.0; // 100% if max tier
    return completedBookings / (completedBookings + bookingsNeeded!);
  }

  @override
  List<Object?> get props => [
    success,
    tier,
    tierLabel,
    tierColor,
    completedBookings,
    benefits,
    nextTier,
    nextTierLabel,
    bookingsNeeded,
  ];
}