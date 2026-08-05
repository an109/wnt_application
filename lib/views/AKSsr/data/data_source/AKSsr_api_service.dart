import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKSsr_model.dart';

abstract class AkSsrApiService {
  Future<Response> getSsr(AkSsrRequestModel request);
}

class AkSsrApiServiceImpl implements AkSsrApiService {
  final Dio dio;

  AkSsrApiServiceImpl(this.dio);

  @override
  Future<Response> getSsr(AkSsrRequestModel request) async {
    try {
      print('CALLING SSR API: ${Urls.akSsr}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.akSsr,
        data: request.toJson(),
      );

      print('SSR Response Status: ${response.statusCode}');
      print('SSR Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('SSR API Error: ${e.message}');
      print('SSR API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('SSR Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akSsr),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
