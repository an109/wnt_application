import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../models/fare_quote_request_model.dart';
import '../models/fare_quote_response_model.dart';

abstract class FareQuoteApiService {
  Future<FareQuoteResponseModel> getFareQuote(FareQuoteRequestModel request);
}

class FareQuoteApiServiceImpl implements FareQuoteApiService {
  final Dio dio;

  FareQuoteApiServiceImpl(this.dio);

  @override
  Future<FareQuoteResponseModel> getFareQuote(FareQuoteRequestModel request) async {
    try {
      print('CALLING FAREQUOTE API: ${Urls.fareQuote}');
      print('Request body: ${request.toJson()}');

      final response = await dio.post(
        Urls.fareQuote,
        data: request.toJson(),
      );

      print('FAREQUOTE API Response Status: ${response.statusCode}');

      return FareQuoteResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.fareQuote),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}