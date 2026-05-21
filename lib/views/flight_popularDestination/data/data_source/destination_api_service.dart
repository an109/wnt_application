import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class PopularDestinationApiService {
  Future<Response> getPopularDestinations();
}

class PopularDestinationApiServiceImpl implements PopularDestinationApiService {
  final Dio dio;

  PopularDestinationApiServiceImpl(this.dio);

  @override
  Future<Response> getPopularDestinations() async {
    try {
      print('CALLING POPULAR DESTINATIONS API: ${Urls.popularsDestinations}');

      final response = await dio.get(
        Urls.popularsDestinations,
        queryParameters: {
          'domain': 'thewandernova.com',
        },
      );

      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.popularsDestinations),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}