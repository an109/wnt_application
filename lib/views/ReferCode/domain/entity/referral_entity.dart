import 'package:equatable/equatable.dart';

class ReferralEntity extends Equatable {
  final bool success;
  final String referralCode;
  final String referralLink;
  final int totalReferrals;
  final String totalEarned;

  /// Per-friend bonus for the referrer (₹) and whether referral bonuses are
  /// switched on. Null on backends that don't send them yet.
  final String? referrerBonus;
  final bool? bonusEnabled;

  const ReferralEntity({
    required this.success,
    required this.referralCode,
    required this.referralLink,
    required this.totalReferrals,
    required this.totalEarned,
    this.referrerBonus,
    this.bonusEnabled,
  });

  @override
  List<Object?> get props => [
    success,
    referralCode,
    referralLink,
    totalReferrals,
    totalEarned,
    referrerBonus,
    bonusEnabled,
  ];
}