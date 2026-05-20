import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../models/VisaDestin_model.dart';

abstract class VisaDestinationApiService {
  Future<VisaDestinationResponseModel> getVisaDestinations({String domain = 'thewandernova.com'});
}

class VisaDestinationApiServiceImpl implements VisaDestinationApiService {
  final Dio dio;

  VisaDestinationApiServiceImpl(this.dio);

  @override
  Future<VisaDestinationResponseModel> getVisaDestinations({String domain = 'thewandernova.com'}) async {
    try {
      print('CALLING VISA DESTINATIONS API: ${Urls.visaDestinations}?domain=$domain');

      final response = await dio.get(
        Urls.visaDestinations,
        queryParameters: {'domain': domain},
      );

      if (response.statusCode == 200 && response.data != null) {
        return VisaDestinationResponseModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: Urls.visaDestinations),
          error: 'Failed to load visa destinations: ${response.statusCode}',
          type: DioExceptionType.badResponse,
          response: response,
        );
      }
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.visaDestinations),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}