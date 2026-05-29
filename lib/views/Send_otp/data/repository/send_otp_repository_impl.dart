import 'package:dio/dio.dart';
import '../../../../UI_helper/contact_type.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/send_otp_Entity.dart';
import '../../domain/repository/end_otp_repository.dart';
import '../../presentation/bloc/send_otp_event.dart';
import '../data_source/send_otp_api_service.dart';

class SendOtpRepositoryImpl implements SendOtpRepository {
  final SendOtpApiService apiService;

  SendOtpRepositoryImpl(this.apiService);

  @override
  Future<DataState<SendOtpEntity>> sendOtp({
    required String contact,
    required ContactType type,
    required String purpose,
  }) async {
    try {
      final response = await apiService.sendOtp(
        contact: contact,
        type: type,
        purpose: purpose,
      );
      return DataSuccess(response);
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}