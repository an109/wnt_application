import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKFareFamilyDetails_model.dart';

abstract class AkFareFamilyDetailsApiService {
  Future<Response> getFareFamilyDetails(
      AkFareFamilyDetailsRequestModel request);
}

class AkFareFamilyDetailsApiServiceImpl
    implements AkFareFamilyDetailsApiService {
  final Dio dio;

  AkFareFamilyDetailsApiServiceImpl(this.dio);

  @override
  Future<Response> getFareFamilyDetails(
      AkFareFamilyDetailsRequestModel request) async {
    try {
      print('CALLING AKBAR FARE FAMILY DETAILS API: ${Urls.fareFamilyDetails}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.fareFamilyDetails,
        data: request.toJson(),
      );

      print('FareFamilyDetails Response Status: ${response.statusCode}');
      print('FareFamilyDetails Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('FareFamilyDetails API Error: ${e.message}');
      print('FareFamilyDetails API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('FareFamilyDetails Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.fareFamilyDetails),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
