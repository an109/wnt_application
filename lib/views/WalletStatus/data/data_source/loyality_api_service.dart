import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class LoyaltyApiService {
  Future<Response> getUserLoyalty();
}

class LoyaltyApiServiceImpl implements LoyaltyApiService {
  final Dio dio;

  LoyaltyApiServiceImpl(this.dio);

  @override
  Future<Response> getUserLoyalty() async {
    try {
      String url = Urls.userLoyalty;
      print('CALLING LOYALTY API: $url');

      final response = await dio.get(url);
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.userLoyalty),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}