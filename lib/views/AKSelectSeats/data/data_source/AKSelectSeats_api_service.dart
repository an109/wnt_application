import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';
import '../model/AKSelectSeats_model.dart';

abstract class AkSelectSeatsApiService {
  Future<Response> selectSeats(AkSelectSeatsRequestModel request);
}

class AkSelectSeatsApiServiceImpl implements AkSelectSeatsApiService {
  final Dio dio;

  AkSelectSeatsApiServiceImpl(this.dio);

  @override
  Future<Response> selectSeats(AkSelectSeatsRequestModel request) async {
    try {
      print('CALLING SELECTSEATS API: ${Urls.akSelectSeats}');
      print('Request Body: ${request.toJson()}');

      final response = await dio.post(
        Urls.akSelectSeats,
        data: request.toJson(),
      );

      print('SelectSeats Response Status: ${response.statusCode}');
      print('SelectSeats Response Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      print('SelectSeats API Error: ${e.message}');
      print('SelectSeats API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('SelectSeats Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.akSelectSeats),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}
