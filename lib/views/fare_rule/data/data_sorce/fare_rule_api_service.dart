import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/fare_rule_models.dart';

abstract class FareRuleApiService {
  Future<Response> getFareRules(FareRuleRequestModel request);
}

class FareRuleApiServiceImpl implements FareRuleApiService {
  final Dio dio;

  FareRuleApiServiceImpl(this.dio);

  @override
  Future<Response> getFareRules(FareRuleRequestModel request) async {
    try {
      print('CALLING FARE RULE API: ${Urls.fareRule}');
      print('Request body: ${request.toJson()}');

      final response = await dio.post(
        Urls.fareRule,
        data: request.toJson(),  // Ensure 'data:' key is used
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('FARE RULE API Response Status: ${response.statusCode}');
      print('FARE RULE API Response Data: ${response.data}');
      return response;

    } on DioException catch (e) {
      print('FareRule API Error: ${e.message}');
      print('FareRule API Error Type: ${e.type}');
      print('FareRule API Error Response: ${e.response?.data}');
      print('FareRule API Error Request: ${e.requestOptions.uri}');
      rethrow;
    } catch (e) {
      print('FareRule Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.fareRule),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}