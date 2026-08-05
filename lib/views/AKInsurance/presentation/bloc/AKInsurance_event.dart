import 'package:equatable/equatable.dart';
import '../../domain/entity/AKInsurance_entity.dart';

abstract class AkInsuranceEvent extends Equatable {
  const AkInsuranceEvent();

  @override
  List<Object?> get props => [];
}

/// Step 2/7 — page-load data for the Trip Secure form.
class LoadAkInsuranceProviderChecklistEvent extends AkInsuranceEvent {
  final AkInsuranceProviderChecklistRequestEntity request;

  const LoadAkInsuranceProviderChecklistEvent(
      [this.request = const AkInsuranceProviderChecklistRequestEntity()]);

  @override
  List<Object?> get props => [request];
}

/// Step 3/7 — prices the trip. The request is retained on the state so the
/// plan-details call can reuse the same trip parameters and tui.
class LoadAkInsuranceQuotesEvent extends AkInsuranceEvent {
  final AkInsuranceQuotesRequestEntity request;

  const LoadAkInsuranceQuotesEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Step 4/7 — full detail for one plan out of the current listing.
class LoadAkInsurancePlanDetailsEvent extends AkInsuranceEvent {
  final String planId;

  const LoadAkInsurancePlanDetailsEvent(this.planId);

  @override
  List<Object?> get props => [planId];
}

/// Picks (or, with a null plan, clears) the plan the traveller wants to add.
class SelectAkInsurancePlanEvent extends AkInsuranceEvent {
  final AkInsurancePlanEntity? plan;

  const SelectAkInsurancePlanEvent(this.plan);

  @override
  List<Object?> get props => [plan];
}

/// Drops the loaded plan detail once its sheet is dismissed.
class ClearAkInsurancePlanDetailsEvent extends AkInsuranceEvent {
  const ClearAkInsurancePlanDetailsEvent();
}

/// Step 5/7 — validates the traveller's ID document before a plan can be
/// paid for. Fired from the KYC form shown right after a plan is picked.
class LoadAkInsuranceKycEvent extends AkInsuranceEvent {
  final AkInsuranceKycRequestEntity request;

  const LoadAkInsuranceKycEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Drops a previous KYC result — fired when the traveller picks a different
/// plan (that plan's own KYC form is a fresh attempt).
class ClearAkInsuranceKycEvent extends AkInsuranceEvent {
  const ClearAkInsuranceKycEvent();
}
