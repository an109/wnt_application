import 'package:dio/dio.dart';
import '../../../../UI_helper/contact_type.dart';
import '../../../../core/constants/urls.dart';
import '../model/send_otp_model.dart';

abstract class SendOtpApiService {
  // Updated signature
  Future<SendOtpModel> sendOtp({
    required String contact,
    required ContactType type,
    required String purpose,
  });
}

class SendOtpApiServiceImpl implements SendOtpApiService {
  final Dio dio;

  SendOtpApiServiceImpl(this.dio);

  @override
  Future<SendOtpModel> sendOtp({
    required String contact,
    required ContactType type,
    required String purpose,
  }) async {
    try {
      print('CALLING SEND OTP API: ${Urls.sendOtp}');

      // Build request body dynamically based on type
      final Map<String, dynamic> requestBody = {'purpose': purpose};
      if (type == ContactType.email) {
        requestBody['email'] = contact;
        print('Sending to email: $contact');
      } else {
        requestBody['phone'] = contact;
        print('Sending to phone: $contact');
      }

      print('Request Body: $requestBody');

      final response = await dio.post(
        Urls.sendOtp,
        data: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      return SendOtpModel.fromJson(response.data);
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.sendOtp),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}