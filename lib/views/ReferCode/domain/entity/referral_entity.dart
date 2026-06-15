import 'package:equatable/equatable.dart';

class ReferralEntity extends Equatable {
  final bool success;
  final String referralCode;
  final String referralLink;
  final int totalReferrals;
  final String totalEarned;

  const ReferralEntity({
    required this.success,
    required this.referralCode,
    required this.referralLink,
    required this.totalReferrals,
    required this.totalEarned,
  });

  @override
  List<Object?> get props => [
    success,
    referralCode,
    referralLink,
    totalReferrals,
    totalEarned,
  ];
}