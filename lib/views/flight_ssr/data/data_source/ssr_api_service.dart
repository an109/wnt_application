import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../models/ssr_request_model.dart';

abstract class SsrApiService {
  Future<Response> getSsrData(SsrRequestModel request);
}

class SsrApiServiceImpl implements SsrApiService {
  final Dio dio;

  SsrApiServiceImpl(this.dio);

  @override
  Future<Response> getSsrData(SsrRequestModel request) async {
    try {
      print('CALLING SSR API: ${Urls.ssr}');
      print('Request payload: ${request.toJson()}');

      final response = await dio.post(
        Urls.ssr,
        data: request.toJson(),
      );

      print('SSR API Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('SSR API Error: ${e.message}');
      print('SSR API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('SSR Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.ssr),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}