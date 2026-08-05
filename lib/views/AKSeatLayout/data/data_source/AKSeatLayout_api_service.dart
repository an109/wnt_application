import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKSeatLayout_model.dart';

abstract class AkSeatLayoutApiService {
  Future<Response> getSeatLayout(AkSeatLayoutRequestModel request);
}

class AkSeatLayoutApiServiceImpl implements AkSeatLayoutApiService {
  final Dio dio;

  AkSeatLayoutApiServiceImpl(this.dio);

  @override
  Future<Response> getSeatLayout(AkSeatLayoutRequestModel request) async {
    try {
      print('CALLING SEATLAYOUT API: ${Urls.akSeatLayout}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.akSeatLayout,
        data: request.toJson(),
      );

      print('SeatLayout Response Status: ${response.statusCode}');
      print('SeatLayout Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('SeatLayout API Error: ${e.message}');
      print('SeatLayout API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('SeatLayout Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akSeatLayout),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
