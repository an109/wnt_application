import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKFareRule_model.dart';

abstract class AkFareRuleApiService {
  Future<Response> getFareRule(AkFareRuleRequestModel request);
}

class AkFareRuleApiServiceImpl implements AkFareRuleApiService {
  final Dio dio;

  AkFareRuleApiServiceImpl(this.dio);

  @override
  Future<Response> getFareRule(AkFareRuleRequestModel request) async {
    try {
      print('CALLING AKBAR FARERULE API: ${Urls.akFareRule}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.akFareRule,
        data: request.toJson(),
      );

      print('FareRule Response Status: ${response.statusCode}');
      print('FareRule Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('FareRule API Error: ${e.message}');
      print('FareRule API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('FareRule Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akFareRule),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
