import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class ReferralApiService {
  Future<Response> getUserReferral();
}

class ReferralApiServiceImpl implements ReferralApiService {
  final Dio dio;

  ReferralApiServiceImpl(this.dio);

  @override
  Future<Response> getUserReferral() async {
    try {
      String url = Urls.userReferral;
      print('CALLING REFERRAL API: $url');

      final response = await dio.get(url);
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.userReferral),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}