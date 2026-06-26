import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../models/booking_request_model.dart';
import '../models/booking_response_model.dart';

abstract class BookingApiService {
  Future<BookingResponseModel> bookFlight(BookingRequestModel request);
}

class BookingApiServiceImpl implements BookingApiService {
  final Dio dio;

  BookingApiServiceImpl(this.dio);

  @override
  Future<BookingResponseModel> bookFlight(BookingRequestModel request) async {
    try {
      print('CALLING BOOK API: ${Urls.book}');
      final payload = request.toJson();
      print('Request body: $payload');

      final response = await dio.post(
        Urls.book,
        data: payload,
      );

      print('BOOK API Response Status: ${response.statusCode}');
      return BookingResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Book API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Book API Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.book),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
