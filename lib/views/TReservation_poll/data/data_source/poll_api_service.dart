import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class ReservationPollApiService {
  Future<Response> getReservationPoll({required String searchId});
}

class ReservationPollApiServiceImpl implements ReservationPollApiService {
  final Dio dio;

  ReservationPollApiServiceImpl(this.dio);

  @override
  Future<Response> getReservationPoll({required String searchId}) async {
    try {
      String url = Urls.reservationPoll(searchId);
      print('CALLING RESERVATION POLL API: $url');

      final response = await dio.get(url);
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.reservationPoll(searchId)),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}