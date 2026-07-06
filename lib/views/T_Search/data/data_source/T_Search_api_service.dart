import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class TransportSearchApiService {
  Future<Response> searchTransport({
    required String startAddress,
    required String endAddress,
    required String pickupDatetime,
    String? returnPickupDatetime,
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
    String? returnPickupDatetime,
    required int numPassengers,
    required String currency,
    required String mode,
  }) async {
    try {
      final url = '${Urls.transportSearch}';

      final body = <String, dynamic>{
        'currency': currency,
        'end_address': endAddress,
        'mode': mode,
        'num_passengers': numPassengers,
        'pickup_datetime': pickupDatetime,
        'start_address': startAddress,
      };

      if (mode == 'round_trip' && returnPickupDatetime != null) {
        body['return_pickup_datetime'] = returnPickupDatetime;
      }

      final response = await dio.post(url, data: body);

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