import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKAcceptFareChange_model.dart';

abstract class AkAcceptFareChangeApiService {
  Future<Response> acceptFareChange(AkAcceptFareChangeRequestModel request);
}

class AkAcceptFareChangeApiServiceImpl implements AkAcceptFareChangeApiService {
  final Dio dio;

  AkAcceptFareChangeApiServiceImpl(this.dio);

  @override
  Future<Response> acceptFareChange(AkAcceptFareChangeRequestModel request) async {
    try {
      print('CALLING ACCEPTFARECHANGE API: ${Urls.acceptFareChange}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.acceptFareChange,
        data: request.toJson(),
      );

      print('AcceptFareChange Response Status: ${response.statusCode}');
      print('AcceptFareChange Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('AcceptFareChange API Error: ${e.message}');
      print('AcceptFareChange API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('AcceptFareChange Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.acceptFareChange),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
