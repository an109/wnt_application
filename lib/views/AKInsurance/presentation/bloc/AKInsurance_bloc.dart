import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../../domain/usecase/AKInsurance_usecase.dart';
import 'AKInsurance_event.dart';
import 'AKInsurance_state.dart';

class AkInsuranceBloc extends Bloc<AkInsuranceEvent, AkInsuranceState> {
  final AkInsuranceSignatureUseCase signatureUseCase;
  final AkInsuranceProviderChecklistUseCase providerChecklistUseCase;
  final AkInsuranceQuotesUseCase quotesUseCase;
  final AkInsurancePlanDetailsUseCase planDetailsUseCase;
  final AkInsuranceValidateKycUseCase validateKycUseCase;

  AkInsuranceBloc({
    required this.signatureUseCase,
    required this.providerChecklistUseCase,
    required this.quotesUseCase,
    required this.planDetailsUseCase,
    required this.validateKycUseCase,
  }) : super(const AkInsuranceState()) {
    on<LoadAkInsuranceProviderChecklistEvent>(_onProviderChecklist);
    on<LoadAkInsuranceQuotesEvent>(_onQuotes);
    on<LoadAkInsurancePlanDetailsEvent>(_onPlanDetails);
    on<SelectAkInsurancePlanEvent>(_onSelectPlan);
    on<ClearAkInsurancePlanDetailsEvent>(_onClearPlanDetails);
    on<LoadAkInsuranceKycEvent>(_onKyc);
    on<ClearAkInsuranceKycEvent>(_onClearKyc);
  }

  /// True when the failure looks like an expired/absent provider token, which
  /// is the one case worth re-minting the signature for.
  bool _isAuthFailure(DataState result) {
    final status = result.error?.response?.statusCode;
    return status == 401 || status == 403;
  }

  Future<void> _onProviderChecklist(
    LoadAkInsuranceProviderChecklistEvent event,
    Emitter<AkInsuranceState> emit,
  ) async {
    emit(state.copyWith(checklistStatus: AkInsuranceStatus.loading, errorMessage: ''));

    final result = await providerChecklistUseCase.call(event.request);

    if (result is DataSuccess<AkInsuranceProviderChecklistEntity>) {
      emit(state.copyWith(
        checklistStatus: AkInsuranceStatus.loaded,
        checklist: result.data,
      ));
    } else {
      // The checklist only tunes the form — a failure here must not block
      // pricing, so it is recorded without an error message.
      emit(state.copyWith(checklistStatus: AkInsuranceStatus.failed));
    }
  }

  Future<void> _onQuotes(
    LoadAkInsuranceQuotesEvent event,
    Emitter<AkInsuranceState> emit,
  ) async {
    emit(state.copyWith(
      quotesStatus: AkInsuranceStatus.loading,
      quotesRequest: event.request,
      errorMessage: '',
    ));

    var result = await quotesUseCase.call(event.request);

    // Signature (step 1/7) mints the Bearer token the provider calls run on.
    // It is normally handled server-side, so it is only re-minted here when a
    // call actually comes back unauthorised — then the listing is retried once.
    if (result is DataFailed && _isAuthFailure(result)) {
      final refreshed = await signatureUseCase.call(
        const AkInsuranceSignatureRequestEntity(forceRefresh: true),
      );
      if (refreshed is DataSuccess<AkInsuranceSignatureEntity>) {
        result = await quotesUseCase.call(event.request);
      }
    }

    if (result is DataSuccess<AkInsuranceQuotesEntity>) {
      final quotes = result.data!;
      final stillValid = quotes.plans.any((p) => p.planId == state.selectedPlan?.planId);
      emit(state.copyWith(
        quotesStatus: AkInsuranceStatus.loaded,
        quotes: quotes,
        // A re-priced trip invalidates a plan that is no longer offered.
        clearSelectedPlan: !stillValid,
      ));
    } else {
      emit(state.copyWith(
        quotesStatus: AkInsuranceStatus.failed,
        errorMessage: result.error?.message?.isNotEmpty == true
            ? result.error!.message!
            : 'Could not fetch travel insurance plans. Please try again.',
      ));
    }
  }

  Future<void> _onPlanDetails(
    LoadAkInsurancePlanDetailsEvent event,
    Emitter<AkInsuranceState> emit,
  ) async {
    final quotesRequest = state.quotesRequest;
    final tui = state.quotes?.tui ?? '';
    if (quotesRequest == null) {
      emit(state.copyWith(
        planDetailsStatus: AkInsuranceStatus.failed,
        errorMessage: 'Plan details are unavailable — please search again.',
      ));
      return;
    }

    emit(state.copyWith(
      planDetailsStatus: AkInsuranceStatus.loading,
      clearPlanDetails: true,
      errorMessage: '',
    ));

    final result = await planDetailsUseCase.call(
      AkInsurancePlanDetailsRequestEntity(
        planId: event.planId,
        countryNames: quotesRequest.countryNames,
        channelId: quotesRequest.channelId,
        policyType: quotesRequest.policyType,
        startDate: quotesRequest.startDate,
        endDate: quotesRequest.endDate,
        isPed: quotesRequest.isPed,
        tenureInMonths: quotesRequest.tenureInMonths,
        travellers: quotesRequest.travellers,
        tui: tui,
      ),
    );

    if (result is DataSuccess<AkInsurancePlanDetailsEntity>) {
      emit(state.copyWith(
        planDetailsStatus: AkInsuranceStatus.loaded,
        planDetails: result.data,
      ));
    } else {
      emit(state.copyWith(
        planDetailsStatus: AkInsuranceStatus.failed,
        errorMessage: 'Could not load this plan. Please try again.',
      ));
    }
  }

  void _onSelectPlan(SelectAkInsurancePlanEvent event, Emitter<AkInsuranceState> emit) {
    if (event.plan == null) {
      emit(state.copyWith(clearSelectedPlan: true));
      return;
    }
    emit(state.copyWith(selectedPlan: event.plan));
  }

  void _onClearPlanDetails(
    ClearAkInsurancePlanDetailsEvent event,
    Emitter<AkInsuranceState> emit,
  ) {
    emit(state.copyWith(
      planDetailsStatus: AkInsuranceStatus.initial,
      clearPlanDetails: true,
    ));
  }

  Future<void> _onKyc(
    LoadAkInsuranceKycEvent event,
    Emitter<AkInsuranceState> emit,
  ) async {
    emit(state.copyWith(kycStatus: AkInsuranceStatus.loading, errorMessage: ''));

    final result = await validateKycUseCase.call(event.request);

    if (result is DataSuccess<AkInsuranceKycEntity> && result.data!.success) {
      emit(state.copyWith(
        kycStatus: AkInsuranceStatus.loaded,
        kycResult: result.data,
        kycRequest: event.request,
      ));
    } else {
      final message = result is DataSuccess<AkInsuranceKycEntity>
          ? result.data!.message
          : result.error?.message;
      emit(state.copyWith(
        kycStatus: AkInsuranceStatus.failed,
        errorMessage: message?.isNotEmpty == true
            ? message!
            : 'Could not verify this ID document. Please check the details and try again.',
      ));
    }
  }

  void _onClearKyc(ClearAkInsuranceKycEvent event, Emitter<AkInsuranceState> emit) {
    emit(state.copyWith(clearKyc: true));
  }
}
