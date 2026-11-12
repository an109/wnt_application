import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKInsurance_model.dart';

abstract class AkInsuranceApiService {
  Future<Response> signature(AkInsuranceSignatureRequestModel request);
  Future<Response> providerChecklist(AkInsuranceProviderChecklistRequestModel request);
  Future<Response> quotesListing(AkInsuranceQuotesRequestModel request);
  Future<Response> planDetails(AkInsurancePlanDetailsRequestModel request);
  Future<Response> validateKyc(AkInsuranceKycRequestModel request);
  Future<Response> startPay(AkInsuranceStartPayRequestModel request);
  Future<Response> getItinerary(AkInsuranceItineraryRequestModel request);
}

class AkInsuranceApiServiceImpl implements AkInsuranceApiService {
  final Dio dio;

  AkInsuranceApiServiceImpl(this.dio);

  Future<Response> _post(String url, String label, Map<String, dynamic> body) async {
    try {
      print('CALLING $label API: $url');
      print('Request Body: $body');

      final response = await dio.post(url, data: body);

      print('$label Response Status: ${response.statusCode}');
      print('$label Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('$label API Error: ${e.message}');
      print('$label API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('$label Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> signature(AkInsuranceSignatureRequestModel request) {
    return _post(Urls.insuranceSignature, 'InsuranceSignature', request.toJson());
  }

  @override
  Future<Response> providerChecklist(AkInsuranceProviderChecklistRequestModel request) {
    return _post(
      Urls.insuranceProviderChecklist,
      'InsuranceProviderChecklist',
      request.toJson(),
    );
  }

  @override
  Future<Response> quotesListing(AkInsuranceQuotesRequestModel request) {
    return _post(Urls.insuranceQuotesListing, 'InsuranceQuotesListing', request.toJson());
  }

  @override
  Future<Response> planDetails(AkInsurancePlanDetailsRequestModel request) {
    return _post(Urls.insurancePlanDetails, 'InsurancePlanDetails', request.toJson());
  }

  @override
  Future<Response> validateKyc(AkInsuranceKycRequestModel request) {
    return _post(Urls.insuranceValidateKyc, 'InsuranceValidateKYC', request.toJson());
  }

  @override
  Future<Response> startPay(AkInsuranceStartPayRequestModel request) async {
    try {
      print('CALLING InsuranceStartPay API: ${Urls.insuranceStartPay}');
      final json = request.toJson();
      final plans = json['Plans'] as List?;
      if (plans != null && plans.isNotEmpty) {
        final travellers = (plans[0] as Map)['Travellers'] as List?;
        if (travellers != null) {
          for (final t in travellers) {
            print('StartPay Traveller PedInfo: ${t['PedInfo']}');
            print('StartPay Traveller QuestionsAnswers: ${t['QuestionsAnswers']}');
          }
        }
      }
      print('Request Body: $json');

      // Mirrors the flight/hotel StartPay convention: a non-200 that still
      // carries a body (e.g. "still processing") is a normal response to be
      // interpreted by the repository, not a thrown DioException.
      final response = await dio.post(
        Urls.insuranceStartPay,
        data: json,
        options: Options(validateStatus: (_) => true),
      );

      print('InsuranceStartPay Response Status: ${response.statusCode}');
      print('InsuranceStartPay Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('InsuranceStartPay API Error: ${e.message}');
      print('InsuranceStartPay API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('InsuranceStartPay Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.insuranceStartPay),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> getItinerary(AkInsuranceItineraryRequestModel request) async {
    try {
      print('CALLING InsuranceGetItinerary API: ${Urls.insuranceGetItinerary}');
      final body = request.toJson();
      print('Request Body: $body');

      final response = await dio.post(
        Urls.insuranceGetItinerary,
        data: body,
        options: Options(validateStatus: (_) => true),
      );

      print('InsuranceGetItinerary Response Status: ${response.statusCode}');
      print('InsuranceGetItinerary Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('InsuranceGetItinerary API Error: ${e.message}');
      print('InsuranceGetItinerary API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('InsuranceGetItinerary Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.insuranceGetItinerary),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
