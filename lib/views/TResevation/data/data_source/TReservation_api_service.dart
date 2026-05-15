import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class TransportReservationApiService {
  Future<Response> createReservation(Map<String, dynamic> requestData);
}

class TransportReservationApiServiceImpl implements TransportReservationApiService {
  final Dio dio;

  TransportReservationApiServiceImpl(this.dio);

  @override
  Future<Response> createReservation(Map<String, dynamic> requestData) async {
    try {
      print('CALLING TRANSPORT RESERVATION API: ${Urls.transportReservations}');
      print('Request data: $requestData');

      final response = await dio.post(
        Urls.transportReservations,
        data: requestData,
      );

      print('Response received successfully');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.transportReservations),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}