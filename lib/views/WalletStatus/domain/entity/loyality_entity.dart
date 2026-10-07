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

  /// Every tier with its unlock threshold and benefits (`tiers` in the API).
  /// Empty on older backends — use [ladder], which fills the gap.
  final List<LoyaltyTierInfo> tiers;

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
    this.tiers = const [],
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
    tiers,
  ];

  /// The full tier ladder, lowest first. Uses the API's `tiers` when present;
  /// otherwise the backend's defaults (same labels, benefits and 2/6/16
  /// thresholds), with the next tier's threshold taken from the live
  /// `bookings_needed` so the progress shown is always accurate.
  List<LoyaltyTierInfo> get ladder {
    if (tiers.isNotEmpty) return tiers;
    final nextThreshold = bookingsNeeded == null || nextTier == null
        ? null
        : completedBookings + bookingsNeeded!;
    return [
      for (final t in LoyaltyTierInfo.defaults)
        if (t.tier == tier)
          LoyaltyTierInfo(
            tier: t.tier,
            label: tierLabel.isEmpty ? t.label : tierLabel,
            color: tierColor.isEmpty ? t.color : tierColor,
            threshold: t.threshold,
            benefits: benefits.isEmpty ? t.benefits : benefits,
          )
        else if (t.tier == nextTier && nextThreshold != null)
          LoyaltyTierInfo(
            tier: t.tier,
            label: t.label,
            color: t.color,
            threshold: nextThreshold,
            benefits: t.benefits,
          )
        else
          t,
    ];
  }
}

/// One rung of the loyalty ladder.
class LoyaltyTierInfo extends Equatable {
  final String tier;
  final String label;
  final String color;
  final int threshold;
  final List<String> benefits;

  const LoyaltyTierInfo({
    required this.tier,
    required this.label,
    required this.color,
    required this.threshold,
    required this.benefits,
  });

  factory LoyaltyTierInfo.fromJson(Map<String, dynamic> json) => LoyaltyTierInfo(
    tier: (json['tier'] ?? '').toString(),
    label: (json['label'] ?? '').toString(),
    color: (json['color'] ?? '').toString(),
    threshold: (json['threshold'] as num?)?.toInt() ?? 0,
    benefits: List<String>.from(json['benefits'] ?? const []),
  );

  Map<String, dynamic> toJson() => {
    'tier': tier,
    'label': label,
    'color': color,
    'threshold': threshold,
    'benefits': benefits,
  };

  /// Mirrors the backend's TIER_META + LoyaltySettings defaults; only used
  /// when an older backend doesn't send `tiers`.
  static const defaults = [
    LoyaltyTierInfo(
      tier: 'bronze',
      label: 'Bronze',
      color: '#CD7F32',
      threshold: 0,
      benefits: ['First-booking discount', 'Basic support', 'Welcome gift'],
    ),
    LoyaltyTierInfo(
      tier: 'silver',
      label: 'Silver',
      color: '#A8A9AD',
      threshold: 2,
      benefits: [
        '5% next-booking voucher',
        'Priority email support',
        'Seat preference saved',
        'Complimentary hotel breakfast',
      ],
    ),
    LoyaltyTierInfo(
      tier: 'gold',
      label: 'Gold',
      color: '#FFD700',
      threshold: 6,
      benefits: [
        '10% next-booking voucher',
        'Priority phone & email support',
        'Seat preference saved',
        'Complimentary hotel breakfast',
        'Lounge access at partner hotels',
        'Early check-in & late check-out',
      ],
    ),
    LoyaltyTierInfo(
      tier: 'platinum',
      label: 'Platinum',
      color: '#E5E4E2',
      threshold: 16,
      benefits: [
        '15% next-booking voucher',
        'Free flight class upgrade (Economy → Business)',
        '24/7 concierge',
        'Automatic room category upgrade',
        'Priority everything',
      ],
    ),
  ];

  @override
  List<Object?> get props => [tier, label, color, threshold, benefits];
}