import 'package:equatable/equatable.dart';
import '../../domain/entity/AKInsurance_entity.dart';

enum AkInsuranceStatus { initial, loading, loaded, failed }

/// A single state object rather than one class per phase: the Trip Secure
/// section renders the quotes list, the picked plan and an optional
/// plan-details sheet at the same time, so those have to coexist.
class AkInsuranceState extends Equatable {
  final AkInsuranceStatus checklistStatus;
  final AkInsuranceProviderChecklistEntity? checklist;

  final AkInsuranceStatus quotesStatus;
  final AkInsuranceQuotesEntity? quotes;

  /// The request that produced [quotes] — replayed into the plan-details call
  /// so both describe the same trip.
  final AkInsuranceQuotesRequestEntity? quotesRequest;

  final AkInsuranceStatus planDetailsStatus;
  final AkInsurancePlanDetailsEntity? planDetails;

  /// The plan the traveller has chosen to add to this booking. Null means
  /// Trip Secure is not being added.
  final AkInsurancePlanEntity? selectedPlan;

  final AkInsuranceStatus kycStatus;
  final AkInsuranceKycEntity? kycResult;

  /// The request KYC last succeeded for — kept so the payment screen can be
  /// handed the exact same document/name/dob StartPay must be called with.
  final AkInsuranceKycRequestEntity? kycRequest;

  final String errorMessage;

  const AkInsuranceState({
    this.checklistStatus = AkInsuranceStatus.initial,
    this.checklist,
    this.quotesStatus = AkInsuranceStatus.initial,
    this.quotes,
    this.quotesRequest,
    this.planDetailsStatus = AkInsuranceStatus.initial,
    this.planDetails,
    this.selectedPlan,
    this.kycStatus = AkInsuranceStatus.initial,
    this.kycResult,
    this.kycRequest,
    this.errorMessage = '',
  });

  List<AkInsurancePlanEntity> get plans => quotes?.plans ?? const [];

  AkInsuranceState copyWith({
    AkInsuranceStatus? checklistStatus,
    AkInsuranceProviderChecklistEntity? checklist,
    AkInsuranceStatus? quotesStatus,
    AkInsuranceQuotesEntity? quotes,
    AkInsuranceQuotesRequestEntity? quotesRequest,
    AkInsuranceStatus? planDetailsStatus,
    AkInsurancePlanDetailsEntity? planDetails,
    bool clearPlanDetails = false,
    AkInsurancePlanEntity? selectedPlan,
    bool clearSelectedPlan = false,
    AkInsuranceStatus? kycStatus,
    AkInsuranceKycEntity? kycResult,
    AkInsuranceKycRequestEntity? kycRequest,
    bool clearKyc = false,
    String? errorMessage,
  }) {
    return AkInsuranceState(
      checklistStatus: checklistStatus ?? this.checklistStatus,
      checklist: checklist ?? this.checklist,
      quotesStatus: quotesStatus ?? this.quotesStatus,
      quotes: quotes ?? this.quotes,
      quotesRequest: quotesRequest ?? this.quotesRequest,
      planDetailsStatus: planDetailsStatus ?? this.planDetailsStatus,
      planDetails: clearPlanDetails ? null : (planDetails ?? this.planDetails),
      selectedPlan: clearSelectedPlan ? null : (selectedPlan ?? this.selectedPlan),
      kycStatus: clearKyc ? AkInsuranceStatus.initial : (kycStatus ?? this.kycStatus),
      kycResult: clearKyc ? null : (kycResult ?? this.kycResult),
      kycRequest: clearKyc ? null : (kycRequest ?? this.kycRequest),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        checklistStatus,
        checklist,
        quotesStatus,
        quotes,
        quotesRequest,
        planDetailsStatus,
        planDetails,
        selectedPlan,
        kycStatus,
        kycResult,
        kycRequest,
        errorMessage,
      ];
}
