import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKSmartPricer_model.dart';

abstract class AkSmartPricerApiService {
  Future<Response> getSmartPricer(AkSmartPricerRequestModel request);
}

class AkSmartPricerApiServiceImpl implements AkSmartPricerApiService {
  final Dio dio;

  AkSmartPricerApiServiceImpl(this.dio);

  @override
  Future<Response> getSmartPricer(AkSmartPricerRequestModel request) async {
    try {
      print('CALLING SMARTPRICER API: ${Urls.smartPricer}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.smartPricer,
        data: request.toJson(),
      );

      print('SmartPricer Response Status: ${response.statusCode}');
      print('SmartPricer Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('SmartPricer API Error: ${e.message}');
      print('SmartPricer API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('SmartPricer Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.smartPricer),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
