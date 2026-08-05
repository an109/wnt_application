import '../../../../core/error/data_state.dart';
import '../entity/AKInsurance_entity.dart';

abstract class AkInsuranceRepository {
  Future<DataState<AkInsuranceSignatureEntity>> signature(
    AkInsuranceSignatureRequestEntity request,
  );

  Future<DataState<AkInsuranceProviderChecklistEntity>> providerChecklist(
    AkInsuranceProviderChecklistRequestEntity request,
  );

  Future<DataState<AkInsuranceQuotesEntity>> quotesListing(
    AkInsuranceQuotesRequestEntity request,
  );

  Future<DataState<AkInsurancePlanDetailsEntity>> planDetails(
    AkInsurancePlanDetailsRequestEntity request,
  );

  Future<DataState<AkInsuranceKycEntity>> validateKyc(
    AkInsuranceKycRequestEntity request,
  );

  Future<DataState<AkInsuranceStartPayEntity>> startPay(
    AkInsuranceStartPayRequestEntity request,
  );

  Future<DataState<AkInsuranceItineraryEntity>> getItinerary(
    AkInsuranceItineraryRequestEntity request,
  );
}
