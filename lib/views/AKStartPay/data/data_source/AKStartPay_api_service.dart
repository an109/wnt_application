import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKStartPay_model.dart';

abstract class AkStartPayApiService {
  Future<Response> startPay(AkStartPayRequestModel request);
}

class AkStartPayApiServiceImpl implements AkStartPayApiService {
  final Dio dio;

  AkStartPayApiServiceImpl(this.dio);

  @override
  Future<Response> startPay(AkStartPayRequestModel request) async {
    try {
      print('CALLING STARTPAY API: ${Urls.startPay}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.startPay,
        data: request.toJson(),
        // 202 (booking still in progress) is a normal, retryable outcome
        // here, not an error — let the repository branch on it instead of
        // dio throwing a DioException for it.
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      print('StartPay Response Status: ${response.statusCode}');
      print('StartPay Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('StartPay API Error: ${e.message}');
      print('StartPay API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('StartPay Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.startPay),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
