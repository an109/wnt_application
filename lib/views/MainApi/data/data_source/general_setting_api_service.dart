import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class GeneralSettingsApiService {
  Future<Response> getPopularDestinationsData({String domain = 'thewandernova.com'});
}

class GeneralSettingsApiServiceImpl implements GeneralSettingsApiService {
  final Dio dio;

  GeneralSettingsApiServiceImpl(this.dio);

  @override
  Future<Response> getPopularDestinationsData({String domain = 'thewandernova.com'}) async {
    try {
      final url = Urls.popularDestinations;
      final queryParams = {'domain': domain};

      print('CALLING POPULAR DESTINATIONS API: $url');
      print('Query params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.popularDestinations),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}