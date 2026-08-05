import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKInsurance_entity.dart';
import '../../domain/repository/AKInsurance_repository.dart';
import '../data_source/AKInsurance_api_service.dart';
import '../model/AKInsurance_model.dart';

class AkInsuranceRepositoryImpl implements AkInsuranceRepository {
  final AkInsuranceApiService apiService;

  AkInsuranceRepositoryImpl(this.apiService);

  DataFailed<T> _failed<T>(String path, String message, {Response? response}) {
    return DataFailed<T>(
      DioException(
        requestOptions: RequestOptions(path: path),
        response: response,
        type: response != null ? DioExceptionType.badResponse : DioExceptionType.unknown,
        error: message,
        // DioException.message defaults to null unless passed explicitly —
        // without this, every caller reading `result.error?.message` (e.g.
        // the bloc) always saw null and silently fell back to a hardcoded
        // generic string, regardless of the message passed in here.
        message: message,
      ),
    );
  }

  @override
  Future<DataState<AkInsuranceSignatureEntity>> signature(
    AkInsuranceSignatureRequestEntity request,
  ) async {
    const path = '/api/akbar-insurance/Signature/';
    try {
      final response = await apiService.signature(
        AkInsuranceSignatureRequestModel.fromEntity(request),
      );

      if (response.statusCode != 200 || response.data is! Map) {
        return _failed(path, 'Could not authenticate with the insurance provider',
            response: response);
      }

      return DataSuccess(
        AkInsuranceSignatureModel.fromJson(
          (response.data as Map).cast<String, dynamic>(),
        ),
      );
    } on DioException catch (e) {
      print('InsuranceSignature Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('InsuranceSignature Repository Unknown Error: $e');
      return _failed(path, e.toString());
    }
  }

  @override
  Future<DataState<AkInsuranceProviderChecklistEntity>> providerChecklist(
    AkInsuranceProviderChecklistRequestEntity request,
  ) async {
    const path = '/api/akbar-insurance/ProviderChecklist/';
    try {
      final response = await apiService.providerChecklist(
        AkInsuranceProviderChecklistRequestModel.fromEntity(request),
      );

      if (response.statusCode != 200 || response.data is! Map) {
        return _failed(path, 'Could not load insurance providers', response: response);
      }

      return DataSuccess(
        AkInsuranceProviderChecklistModel.fromJson(
          (response.data as Map).cast<String, dynamic>(),
        ),
      );
    } on DioException catch (e) {
      print('InsuranceProviderChecklist Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('InsuranceProviderChecklist Repository Unknown Error: $e');
      return _failed(path, e.toString());
    }
  }

  @override
  Future<DataState<AkInsuranceQuotesEntity>> quotesListing(
    AkInsuranceQuotesRequestEntity request,
  ) async {
    const path = '/api/akbar-insurance/QuotesListing/';
    try {
      final response = await apiService.quotesListing(
        AkInsuranceQuotesRequestModel.fromEntity(request),
      );

      if (response.statusCode != 200) {
        return _failed(path, 'Could not fetch insurance quotes', response: response);
      }

      // The rate sheet is CSV-backed upstream, so "no cover for this
      // destination/date range" can come back as a bare string rather than
      // JSON. That is an empty result, not a transport failure — surface it as
      // a loaded-but-empty listing so the section shows a message instead of
      // an error card.
      if (response.data is! Map) {
        return DataSuccess(
          AkInsuranceQuotesModel.empty(
            response.data?.toString() ?? 'No plans available for this trip.',
          ),
        );
      }

      return DataSuccess(
        AkInsuranceQuotesModel.fromJson((response.data as Map).cast<String, dynamic>()),
      );
    } on DioException catch (e) {
      print('InsuranceQuotesListing Repository Error: ${e.message}');
      print('InsuranceQuotesListing Repository Error Response: ${e.response?.data}');
      // Dio's default validateStatus throws for any non-2xx, so a "no rate
      // sheet row matches this search" answer from the rate-sheet-backed
      // upstream — which it sends as e.g. a 502 with a JSON body like
      // {"success":false,"error":"...No plans available..."} rather than a
      // 200 with an empty list — lands here, not in the branches above. That
      // is an empty result, not a transport failure, so surface the
      // provider's own reason as a loaded-but-empty listing (mirrors the
      // bare-string 502 case already handled above) instead of a scary
      // error/retry card.
      final errorData = e.response?.data;
      if (errorData is Map) {
        final message = (errorData['error'] ?? errorData['message'])?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return DataSuccess(AkInsuranceQuotesModel.empty(message));
        }
      }
      return DataFailed(e);
    } catch (e) {
      print('InsuranceQuotesListing Repository Unknown Error: $e');
      return _failed(path, e.toString());
    }
  }

  @override
  Future<DataState<AkInsurancePlanDetailsEntity>> planDetails(
    AkInsurancePlanDetailsRequestEntity request,
  ) async {
    const path = '/api/akbar-insurance/PlanDetails/';
    try {
      final response = await apiService.planDetails(
        AkInsurancePlanDetailsRequestModel.fromEntity(request),
      );

      if (response.statusCode != 200 || response.data is! Map) {
        return _failed(path, 'Could not load plan details', response: response);
      }

      return DataSuccess(
        AkInsurancePlanDetailsModel.fromJson(
          (response.data as Map).cast<String, dynamic>(),
        ),
      );
    } on DioException catch (e) {
      print('InsurancePlanDetails Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('InsurancePlanDetails Repository Unknown Error: $e');
      return _failed(path, e.toString());
    }
  }

  @override
  Future<DataState<AkInsuranceKycEntity>> validateKyc(
    AkInsuranceKycRequestEntity request,
  ) async {
    const path = '/api/akbar-insurance/ValidateKYC/';
    try {
      final response = await apiService.validateKyc(
        AkInsuranceKycRequestModel.fromEntity(request),
      );

      if (response.statusCode != 200 || response.data is! Map) {
        return _failed(path, 'Could not verify this ID document', response: response);
      }

      return DataSuccess(
        AkInsuranceKycModel.fromJson((response.data as Map).cast<String, dynamic>()),
      );
    } on DioException catch (e) {
      print('InsuranceValidateKYC Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('InsuranceValidateKYC Repository Unknown Error: $e');
      return _failed(path, e.toString());
    }
  }

  @override
  Future<DataState<AkInsuranceStartPayEntity>> startPay(
    AkInsuranceStartPayRequestEntity request,
  ) async {
    const path = '/api/akbar-insurance/StartPay/';
    try {
      final response = await apiService.startPay(
        AkInsuranceStartPayRequestModel.fromEntity(request),
      );

      if (response.statusCode != 200) {
        return _failed(path, 'Could not issue the Trip Secure policy', response: response);
      }

      if (response.data is! Map) {
        return DataSuccess(
          AkInsuranceStartPayModel.empty(response.data?.toString() ?? 'Unexpected response.'),
        );
      }

      return DataSuccess(
        AkInsuranceStartPayModel.fromJson((response.data as Map).cast<String, dynamic>()),
      );
    } on DioException catch (e) {
      print('InsuranceStartPay Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('InsuranceStartPay Repository Unknown Error: $e');
      return _failed(path, e.toString());
    }
  }

  @override
  Future<DataState<AkInsuranceItineraryEntity>> getItinerary(
    AkInsuranceItineraryRequestEntity request,
  ) async {
    const path = '/api/akbar-insurance/GetItinerary/';
    try {
      final response = await apiService.getItinerary(
        AkInsuranceItineraryRequestModel.fromEntity(request),
      );

      if (response.statusCode != 200 || response.data is! Map) {
        return _failed(path, 'Could not load the policy confirmation', response: response);
      }

      return DataSuccess(
        AkInsuranceItineraryModel.fromJson((response.data as Map).cast<String, dynamic>()),
      );
    } on DioException catch (e) {
      print('InsuranceGetItinerary Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('InsuranceGetItinerary Repository Unknown Error: $e');
      return _failed(path, e.toString());
    }
  }
}
