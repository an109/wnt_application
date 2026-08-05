import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKGetSPricer_model.dart';

abstract class AkGetSPricerApiService {
  Future<Response> getSPricer(AkGetSPricerRequestModel request);
}

class AkGetSPricerApiServiceImpl implements AkGetSPricerApiService {
  final Dio dio;

  AkGetSPricerApiServiceImpl(this.dio);

  @override
  Future<Response> getSPricer(AkGetSPricerRequestModel request) async {
    try {
      print('CALLING GETSPRICER API: ${Urls.getSPricer}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.getSPricer,
        data: request.toJson(),
      );

      print('GetSPricer Response Status: ${response.statusCode}');
      print('GetSPricer Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('GetSPricer API Error: ${e.message}');
      print('GetSPricer API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('GetSPricer Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.getSPricer),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
