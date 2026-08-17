import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wander_nova/core/constants/urls.dart';

abstract class SupportApiService {
  Future<Response> submitSupportQuery({
    required String bookingReference,
    required String email,
    required String phoneCode,
    required String phone,
    required String queryType,
    required String flightType,
    required String message,
    PlatformFile? attachment,
  });
}

class SupportApiServiceImpl implements SupportApiService {
  final Dio dio;

  SupportApiServiceImpl(this.dio);

  @override
  Future<Response> submitSupportQuery({
    required String bookingReference,
    required String email,
    required String phoneCode,
    required String phone,
    required String queryType,
    required String flightType,
    required String message,
    PlatformFile? attachment,
  }) async {
    final formData = FormData.fromMap({
      'booking_reference': bookingReference,
      'email': email,
      'phone_code': phoneCode,
      'phone': phone,
      'query_type': queryType,
      'flight_type': flightType,
      'message': message,
      if (attachment != null && attachment.path != null)
        'attachment': await MultipartFile.fromFile(
          attachment.path!,
          filename: attachment.name,
        ),
    });

    return dio.post(
      Urls.supportQuerySubmit,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
  }
}
