import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelAutosuggestApiService {
  Future<Response> autosuggest(String term);
}

class AkHotelAutosuggestApiServiceImpl implements AkHotelAutosuggestApiService {
  final Dio dio;

  AkHotelAutosuggestApiServiceImpl(this.dio);

  @override
  Future<Response> autosuggest(String term) async {
    try {
      print('CALLING AKBAR HOTEL AUTOSUGGEST API: ${Urls.akHotelAutosuggest}?term=$term');

      final response = await dio.get(
        Urls.akHotelAutosuggest,
        queryParameters: {'term': term},
      );

      print('Autosuggest Response Status: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('Autosuggest API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Autosuggest Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akHotelAutosuggest),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
