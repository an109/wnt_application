import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class HolidayApiService {
  Future<Response> getPopularDestinations({String? domain});
}

class HolidayApiServiceImpl implements HolidayApiService {
  final Dio dio;

  HolidayApiServiceImpl(this.dio);

  @override
  Future<Response> getPopularDestinations({String? domain}) async {
    try {
      Map<String, dynamic> queryParams = {};

      if (domain != null && domain.isNotEmpty) {
        queryParams['domain'] = domain;
      }

      print('CALLING HOLIDAYS POPULAR DESTINATIONS API: ${Urls.holidaysPopularDestinations}');
      print('Query params: $queryParams');

      final response = await dio.get(
        Urls.holidaysPopularDestinations,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.holidaysPopularDestinations),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}