import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class FooterSettingsApiService {
  Future<Response> getFooterSettings({required String domain});
}

class FooterSettingsApiServiceImpl implements FooterSettingsApiService {
  final Dio dio;

  FooterSettingsApiServiceImpl(this.dio);

  @override
  Future<Response> getFooterSettings({required String domain}) async {
    try {
      print('CALLING FOOTER SETTINGS API: ${Urls.footerSettings}');
      print('Query params: domain=$domain');

      final response = await dio.get(
        Urls.footerSettings,
        queryParameters: {'domain': domain},
      );
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.footerSettings),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}