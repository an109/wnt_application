import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class VisaApplicationApiService {
  Future<Response> getAllVisaApplications();
  Future<Response> getVisaApplicationById(int id);
  Future<Response> createVisaApplication(Map<String, dynamic> data);
}

class VisaApplicationApiServiceImpl implements VisaApplicationApiService {
  final Dio dio;

  VisaApplicationApiServiceImpl(this.dio);

  @override
  Future<Response> getAllVisaApplications() async {
    try {
      print('CALLING GET ALL VISA APPLICATIONS API: ${Urls.visaApplications}');

      final response = await dio.get(Urls.visaApplications);

      print('GET ALL VISA APPLICATIONS RESPONSE STATUS: ${response.statusCode}');
      print('GET ALL VISA APPLICATIONS RESPONSE DATA: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('GET ALL VISA APPLICATIONS API ERROR: ${e.message}');
      print('GET ALL VISA APPLICATIONS API ERROR TYPE: ${e.type}');
      rethrow;
    } catch (e) {
      print('GET ALL VISA APPLICATIONS UNKNOWN ERROR: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.visaApplications),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> getVisaApplicationById(int id) async {
    try {
      final url = '${Urls.visaApplicationDetail}$id/';
      print('CALLING GET VISA APPLICATION BY ID API: $url');

      final response = await dio.get(url);

      print('GET VISA APPLICATION BY ID RESPONSE STATUS: ${response.statusCode}');
      print('GET VISA APPLICATION BY ID RESPONSE DATA: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('GET VISA APPLICATION BY ID API ERROR: ${e.message}');
      print('GET VISA APPLICATION BY ID API ERROR TYPE: ${e.type}');
      rethrow;
    } catch (e) {
      print('GET VISA APPLICATION BY ID UNKNOWN ERROR: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '${Urls.visaApplicationDetail}$id/'),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<Response> createVisaApplication(Map<String, dynamic> data) async {
    try {
      print('CALLING CREATE VISA APPLICATION API: ${Urls.visaApplications}');
      print('CREATE VISA APPLICATION REQUEST BODY: $data');

      final response = await dio.post(
        Urls.visaApplications,
        data: data,
      );

      print('CREATE VISA APPLICATION RESPONSE STATUS: ${response.statusCode}');
      print('CREATE VISA APPLICATION RESPONSE DATA: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('CREATE VISA APPLICATION API ERROR: ${e.message}');
      print('CREATE VISA APPLICATION API ERROR TYPE: ${e.type}');
      if (e.response != null) {
        print('CREATE VISA APPLICATION API ERROR RESPONSE: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      print('CREATE VISA APPLICATION UNKNOWN ERROR: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.visaApplications),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}