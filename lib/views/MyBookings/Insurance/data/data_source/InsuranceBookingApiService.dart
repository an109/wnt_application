import 'package:dio/dio.dart';
import '../../../../../core/constants/urls.dart';

abstract class InsuranceBookingApiService {
  Future<Response> getInsuranceBookings(int userId);
}

class InsuranceBookingApiServiceImpl implements InsuranceBookingApiService {
  final Dio dio;

  InsuranceBookingApiServiceImpl(this.dio);

  @override
  Future<Response> getInsuranceBookings(int userId) async {
    try {
      final response = await dio.get(
        Urls.insuranceBookings,
        queryParameters: {'user_id': userId},
      );
      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: Urls.insuranceBookings),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
