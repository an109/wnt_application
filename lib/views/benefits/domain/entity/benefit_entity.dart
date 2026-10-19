import 'package:equatable/equatable.dart';

/// One earnable step of the headline benefit amount.
class BenefitMilestone extends Equatable {
  final String code;
  final String label;
  final String description;
  final double amount;
  final String icon;

  /// True for "refer a friend", which pays once per referral.
  final bool repeatable;
  final int maxClaims;
  final int claimsMade;

  /// What this traveller has actually been paid for this milestone.
  final double earned;
  final bool completed;

  const BenefitMilestone({
    required this.code,
    required this.label,
    required this.description,
    required this.amount,
    this.icon = '',
    this.repeatable = false,
    this.maxClaims = 1,
    this.claimsMade = 0,
    this.earned = 0,
    this.completed = false,
  });

  /// Milestones the app can claim itself. Everything else is granted by the
  /// server when a booking settles — the client is not trusted to say it
  /// booked something.
  bool get isSelfServe =>
      code == 'profile_complete' || code == 'app_share';

  @override
  List<Object?> get props =>
      [code, label, amount, claimsMade, earned, completed];
}

/// A loyalty tier and how far this traveller is from reaching it.
class BenefitTier extends Equatable {
  final String tier;
  final String label;
  final int rank;
  final String colour;
  final List<String> perks;

  final int requiredFlights;
  final int requiredHotels;
  final int requiredHolidays;
  final int requiredTotal;

  /// Cashback percentage per vertical, keyed 'flight', 'hotel', …
  final Map<String, double> cashbackPercent;
  final double cashbackMaxAmount;

  final bool achieved;

  /// What is still missing, keyed by vertical. Empty once reached.
  final Map<String, int> stillNeeded;

  const BenefitTier({
    required this.tier,
    required this.label,
    required this.rank,
    this.colour = '',
    this.perks = const [],
    this.requiredFlights = 0,
    this.requiredHotels = 0,
    this.requiredHolidays = 0,
    this.requiredTotal = 0,
    this.cashbackPercent = const {},
    this.cashbackMaxAmount = 0,
    this.achieved = false,
    this.stillNeeded = const {},
  });

  @override
  List<Object?> get props => [tier, rank, achieved, stillNeeded];
}

/// Completed-booking counts behind the current tier.
class BenefitTierProgress extends Equatable {
  final String current;
  final Map<String, int> counts;
  final double lifetimeSpend;
  final double totalCashbackEarned;
  final List<BenefitTier> allTiers;

  const BenefitTierProgress({
    required this.current,
    this.counts = const {},
    this.lifetimeSpend = 0,
    this.totalCashbackEarned = 0,
    this.allTiers = const [],
  });

  int countFor(String vertical) => counts[vertical] ?? 0;

  /// The next tier up, or null when already at the top.
  BenefitTier? get nextTier {
    final sorted = [...allTiers]..sort((a, b) => a.rank.compareTo(b.rank));
    for (final t in sorted) {
      if (!t.achieved && t.stillNeeded.isNotEmpty) return t;
    }
    return null;
  }

  @override
  List<Object?> get props => [current, counts, lifetimeSpend];
}

/// Everything the Benefits screen renders, from one call.
class BenefitSummary extends Equatable {
  final bool enabled;
  final double headlineAmount;
  final String termsUrl;

  /// Promotional credit. Capped per booking and never withdrawable — kept
  /// separate from [walletBalance], which is real money.
  final double benefitBalance;
  final double availableBenefitBalance;
  final double walletBalance;
  final String currency;

  final double totalPossible;
  final double totalEarned;

  final List<BenefitMilestone> milestones;
  final BenefitTierProgress tier;
  final String referralCode;

  const BenefitSummary({
    required this.enabled,
    required this.headlineAmount,
    this.termsUrl = '',
    this.benefitBalance = 0,
    this.availableBenefitBalance = 0,
    this.walletBalance = 0,
    this.currency = 'INR',
    this.totalPossible = 0,
    this.totalEarned = 0,
    this.milestones = const [],
    required this.tier,
    this.referralCode = '',
  });

  double get progressFraction =>
      totalPossible <= 0 ? 0 : (totalEarned / totalPossible).clamp(0.0, 1.0);

  @override
  List<Object?> get props =>
      [enabled, benefitBalance, totalEarned, milestones, tier];
}

/// The server's answer to "how much credit can this booking take?".
///
/// [maxRedeemable] is already the minimum of every cap, so the app renders it
/// rather than recomputing anything. [reason] explains the number, which
/// matters when the cap lands well under what the traveller expected.
class BenefitQuote extends Equatable {
  final bool success;
  final String bookingType;
  final double bookingAmount;
  final double maxRedeemable;
  final String reason;
  final double availableBalance;

  const BenefitQuote({
    required this.success,
    this.bookingType = '',
    this.bookingAmount = 0,
    this.maxRedeemable = 0,
    this.reason = '',
    this.availableBalance = 0,
  });

  bool get canRedeem => success && maxRedeemable > 0;

  const BenefitQuote.unavailable(this.reason)
      : success = false,
        bookingType = '',
        bookingAmount = 0,
        maxRedeemable = 0,
        availableBalance = 0;

  @override
  List<Object?> get props => [success, maxRedeemable, reason];
}

/// Credit reserved for the duration of a checkout.
///
/// Taken before the payment gateway opens and settled after: captured when
/// payment succeeds, released when it does not. Without the hold, the same
/// credit could be spent twice from two screens, or lost to a payment the
/// traveller abandoned halfway.
class BenefitHold extends Equatable {
  final bool success;
  final String holdReference;
  final double appliedAmount;
  final double remainingToPay;
  final DateTime? expiresAt;
  final String error;

  const BenefitHold({
    required this.success,
    this.holdReference = '',
    this.appliedAmount = 0,
    this.remainingToPay = 0,
    this.expiresAt,
    this.error = '',
  });

  const BenefitHold.failed(this.error)
      : success = false,
        holdReference = '',
        appliedAmount = 0,
        remainingToPay = 0,
        expiresAt = null;

  @override
  List<Object?> get props => [success, holdReference, appliedAmount];
}
