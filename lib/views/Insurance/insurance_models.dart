import '../AKInsurance/domain/entity/AKInsurance_entity.dart';

/// Payload handed over by InsuranceSearchCard → GET QUOTES.
///
/// Kept in its own file (no dependents) so [InsuranceQuoteRequest] and
/// [InsurancePolicy] can be shared by the quotes, booking, and payment
/// screens without those screens importing each other and forming an
/// import cycle.
class InsuranceQuoteRequest {
  final String insuranceType;
  final String fromCountry;
  final List<String> travellingCountries;
  final DateTime startDate;
  final DateTime endDate;
  final int noOfDays;
  final List<DateTime?> travellerDobs;
  // One of SELF/SPOUSE/CHILD/PARENT/SIBLING/FRIEND per traveller, index-
  // aligned with travellerDobs — QuotesListing/PlanDetails' documented enum
  // for travellers[].relation. Defaulted so old call sites that don't pass
  // it keep compiling; use relationFor(i) rather than indexing directly.
  final List<String> travellerRelations;

  const InsuranceQuoteRequest({
    required this.insuranceType,
    required this.fromCountry,
    required this.travellingCountries,
    required this.startDate,
    required this.endDate,
    required this.noOfDays,
    required this.travellerDobs,
    this.travellerRelations = const [],
  });

  int get travellers => travellerDobs.length;
  String get destination =>
      travellingCountries.isEmpty ? '—' : travellingCountries.join(', ');

  /// SELF for the lead traveller; whatever was collected for the rest,
  /// falling back to SPOUSE (a valid enum value) if none was supplied.
  String relationFor(int i) =>
      i == 0 ? 'SELF' : (i < travellerRelations.length ? travellerRelations[i] : 'SPOUSE');
}

/// Display model for one plan — built from the live [AkInsurancePlanEntity]
/// the QuotesListing call returns.
class InsurancePolicy {
  final String planId;
  final String supplier;
  final String planName;
  final int coverageUsd;
  final int premiumInr;
  const InsurancePolicy({
    required this.planId,
    required this.supplier,
    required this.planName,
    required this.coverageUsd,
    required this.premiumInr,
  });

  factory InsurancePolicy.fromPlan(AkInsurancePlanEntity plan) {
    return InsurancePolicy(
      planId: plan.planId,
      supplier: plan.provider.isNotEmpty ? plan.provider : plan.planName,
      planName: plan.planName,
      coverageUsd: plan.sumInsured.round(),
      premiumInr: plan.premium.round(),
    );
  }
}
