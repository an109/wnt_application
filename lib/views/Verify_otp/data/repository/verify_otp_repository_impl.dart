import 'package:dio/dio.dart';
import '../../../../UI_helper/contact_type.dart';
import '../../../Send_otp/presentation/bloc/send_otp_event.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/verify_otp_entity.dart';
import '../../domain/repository/verify_otp_repository.dart';
import '../data_source/verify_otp_api_service.dart';

class VerifyOtpRepositoryImpl implements VerifyOtpRepository {
  final VerifyOtpApiService apiService;

  VerifyOtpRepositoryImpl(this.apiService);

  @override
  Future<DataState<VerifyOtpEntity>> verifyOtp({
    required String contact,
    required ContactType type,
    required String otp,
  }) async {
    try {
      final response = await apiService.verifyOtp(
        contact: contact,
        type: type,
        otp: otp,
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