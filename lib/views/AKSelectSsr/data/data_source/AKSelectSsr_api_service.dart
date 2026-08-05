import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKSelectSsr_model.dart';

abstract class AkSelectSsrApiService {
  Future<Response> selectSsr(AkSelectSsrRequestModel request);
}

class AkSelectSsrApiServiceImpl implements AkSelectSsrApiService {
  final Dio dio;

  AkSelectSsrApiServiceImpl(this.dio);

  @override
  Future<Response> selectSsr(AkSelectSsrRequestModel request) async {
    try {
      print('CALLING SELECTSSR API: ${Urls.akSelectSsr}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.akSelectSsr,
        data: request.toJson(),
      );

      print('SelectSSR Response Status: ${response.statusCode}');
      print('SelectSSR Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('SelectSSR API Error: ${e.message}');
      print('SelectSSR API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('SelectSSR Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akSelectSsr),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
