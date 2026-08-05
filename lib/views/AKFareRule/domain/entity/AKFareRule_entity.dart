import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Request
// ---------------------------------------------------------------------------

class AkFareRuleTripRequestEntity extends Equatable {
  final String index;
  final double amount;
  final int orderId;

  const AkFareRuleTripRequestEntity({
    required this.index,
    required this.amount,
    required this.orderId,
  });

  @override
  List<Object?> get props => [index, amount, orderId];
}

class AkFareRuleRequestEntity extends Equatable {
  // The original ExpressSearch/GetExpSearch tui — NOT the pricing tui.
  final String tui;
  final List<AkFareRuleTripRequestEntity> trips;

  const AkFareRuleRequestEntity({
    required this.tui,
    required this.trips,
  });

  @override
  List<Object?> get props => [tui, trips];
}

// ---------------------------------------------------------------------------
// Response
// ---------------------------------------------------------------------------

/// The doc only specifies this endpoint returns "cancellation and
/// change-fee slabs" without pinning down exact field names, so this is
/// parsed defensively: [ruleTexts] flattens whatever rule text is found
/// under common key names, and [raw] keeps the untouched response as a
/// fallback for rendering if [ruleTexts] comes back empty.
class AkFareRuleEntity extends Equatable {
  final bool success;
  final List<String> ruleTexts;
  final Map<String, dynamic> raw;

  const AkFareRuleEntity({
    required this.success,
    required this.ruleTexts,
    required this.raw,
  });

  @override
  List<Object?> get props => [success, ruleTexts, raw];
}
