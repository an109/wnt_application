import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class TransportSearchApiService {
  Future<Response> searchTransport({
    required String startAddress,
    required String endAddress,
    required String pickupDatetime,
    required int numPassengers,
    required String currency,
    required String mode,
  });
}

class TransportSearchApiServiceImpl implements TransportSearchApiService {
  final Dio dio;

  TransportSearchApiServiceImpl(this.dio);

  @override
  Future<Response> searchTransport({
    required String startAddress,
    required String endAddress,
    required String pickupDatetime,
    required int numPassengers,
    required String currency,
    required String mode,
  }) async {
    try {
      final url = '${Urls.transportSearch}';

      print('API CALL: POST $url');
      print('Request Body: {');
      print('  "currency": "$currency",');
      print('  "end_address": "$endAddress",');
      print('  "mode": "$mode",');
      print('  "num_passengers": $numPassengers,');
      print('  "pickup_datetime": "$pickupDatetime",');
      print('  "start_address": "$startAddress"');
      print('}');

      final response = await dio.post(
        url,
        data: {
          'currency': currency,
          'end_address': endAddress,
          'mode': mode,
          'num_passengers': numPassengers,
          'pickup_datetime': pickupDatetime,
          'start_address': startAddress,
        },
      );

      print('API RESPONSE: Status ${response.statusCode}, Data: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '${Urls.transportSearch}'),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }
}