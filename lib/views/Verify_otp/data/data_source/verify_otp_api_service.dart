import 'package:dio/dio.dart';
import '../../../../UI_helper/contact_type.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../../core/constants/urls.dart';
import '../model/verify_otp_model.dart';

abstract class VerifyOtpApiService {
  Future<VerifyOtpModel> verifyOtp({
    required String contact,
    required ContactType type,
    required String otp,
  });
}

class VerifyOtpApiServiceImpl implements VerifyOtpApiService {
  final Dio dio;

  VerifyOtpApiServiceImpl(this.dio);

  @override
  Future<VerifyOtpModel> verifyOtp({
    required String contact,
    required ContactType type,
    required String otp,
  }) async {
    try {
      print('CALLING VERIFY OTP API: ${Urls.verifyOtp}');

      // Build request body dynamically based on type
      final Map<String, dynamic> requestBody = {'otp': otp};
      if (type == ContactType.email) {
        requestBody['email'] = contact;
        print('Verifying email: $contact with OTP: $otp');
      } else {
        requestBody['phone'] = contact;
        print('Verifying phone: $contact with OTP: $otp');
      }

      print('Request Body: $requestBody');

      final response = await dio.post(
        Urls.verifyOtp,
        data: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      return VerifyOtpModel.fromJson(response.data);
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.verifyOtp),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}