import '../../domain/entity/referral_entity.dart';

class ReferralModel extends ReferralEntity {
  const ReferralModel({
    required super.success,
    required super.referralCode,
    required super.referralLink,
    required super.totalReferrals,
    required super.totalEarned,
    super.referrerBonus,
    super.bonusEnabled,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      success: json['success'] ?? false,
      referralCode: json['referral_code'] ?? '',
      referralLink: json['referral_link'] ?? '',
      totalReferrals: json['total_referrals'] ?? 0,
      totalEarned: json['total_earned'] ?? '0.00',
      referrerBonus: json['referrer_bonus']?.toString(),
      bonusEnabled: json['referral_bonus_enabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'referral_code': referralCode,
      'referral_link': referralLink,
      'total_referrals': totalReferrals,
      'total_earned': totalEarned,
      'referrer_bonus': referrerBonus,
      'referral_bonus_enabled': bonusEnabled,
    };
  }
}