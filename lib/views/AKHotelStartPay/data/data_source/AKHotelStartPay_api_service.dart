import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class AkHotelStartPayApiService {
  Future<Response> startPay(Map<String, dynamic> body);
}

class AkHotelStartPayApiServiceImpl implements AkHotelStartPayApiService {
  final Dio dio;

  AkHotelStartPayApiServiceImpl(this.dio);

  @override
  Future<Response> startPay(Map<String, dynamic> body) async {
    try {
      print('CALLING AKBAR HOTEL START PAY API: ${Urls.akHotelStartPay}');
      print('Request Body: $body');

      final response = await dio.post(
        Urls.akHotelStartPay,
        data: body,
        // StartPay is gate-heavy (503 kill-switch off, 402 unverified
        // payment) — those aren't transport failures, they're the backend
        // telling the caller why booking was refused, so read the body
        // instead of letting Dio throw.
        options: Options(validateStatus: (status) => status != null),
      );

      print('Start Pay Response Status: ${response.statusCode}');
      print('Start Pay Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('Start Pay API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Start Pay Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akHotelStartPay),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
