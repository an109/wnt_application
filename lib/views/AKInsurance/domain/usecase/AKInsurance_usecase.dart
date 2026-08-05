import '../../../../core/error/data_state.dart';
import '../entity/AKInsurance_entity.dart';
import '../repository/AKInsurance_repository.dart';

class AkInsuranceSignatureUseCase {
  final AkInsuranceRepository repository;

  AkInsuranceSignatureUseCase(this.repository);

  Future<DataState<AkInsuranceSignatureEntity>> call(
    AkInsuranceSignatureRequestEntity request,
  ) =>
      repository.signature(request);
}

class AkInsuranceProviderChecklistUseCase {
  final AkInsuranceRepository repository;

  AkInsuranceProviderChecklistUseCase(this.repository);

  Future<DataState<AkInsuranceProviderChecklistEntity>> call(
    AkInsuranceProviderChecklistRequestEntity request,
  ) =>
      repository.providerChecklist(request);
}

class AkInsuranceQuotesUseCase {
  final AkInsuranceRepository repository;

  AkInsuranceQuotesUseCase(this.repository);

  Future<DataState<AkInsuranceQuotesEntity>> call(
    AkInsuranceQuotesRequestEntity request,
  ) =>
      repository.quotesListing(request);
}

class AkInsurancePlanDetailsUseCase {
  final AkInsuranceRepository repository;

  AkInsurancePlanDetailsUseCase(this.repository);

  Future<DataState<AkInsurancePlanDetailsEntity>> call(
    AkInsurancePlanDetailsRequestEntity request,
  ) =>
      repository.planDetails(request);
}

class AkInsuranceValidateKycUseCase {
  final AkInsuranceRepository repository;

  AkInsuranceValidateKycUseCase(this.repository);

  Future<DataState<AkInsuranceKycEntity>> call(
    AkInsuranceKycRequestEntity request,
  ) =>
      repository.validateKyc(request);
}

class AkInsuranceStartPayUseCase {
  final AkInsuranceRepository repository;

  AkInsuranceStartPayUseCase(this.repository);

  Future<DataState<AkInsuranceStartPayEntity>> call(
    AkInsuranceStartPayRequestEntity request,
  ) =>
      repository.startPay(request);
}

class AkInsuranceGetItineraryUseCase {
  final AkInsuranceRepository repository;

  AkInsuranceGetItineraryUseCase(this.repository);

  Future<DataState<AkInsuranceItineraryEntity>> call(
    AkInsuranceItineraryRequestEntity request,
  ) =>
      repository.getItinerary(request);
}
