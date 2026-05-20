import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class VisaPopularDestinationApiService {
  Future<Response> getVisaDestinations({String? domain});
}

class VisaPopularDestinationApiServiceImpl implements VisaPopularDestinationApiService {
  final Dio dio;

  VisaPopularDestinationApiServiceImpl(this.dio);

  @override
  Future<Response> getVisaDestinations({String? domain}) async {
    try {
      final url = Urls.visaPopularDestinations;
      final queryParams = <String, dynamic>{};

      if (domain != null && domain.isNotEmpty) {
        queryParams['domain'] = domain;
      }

      print('CALLING VISA DESTINATIONS API: $url');
      print('Query params: $queryParams');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );

      print('API Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('API Error Type: ${e.type}');
      print('API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.visaPopularDestinations),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}