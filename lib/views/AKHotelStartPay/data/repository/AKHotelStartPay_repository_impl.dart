import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKHotelStartPay_entity.dart';
import '../../domain/repository/AKHotelStartPay_repository.dart';
import '../data_source/AKHotelStartPay_api_service.dart';
import '../model/AKHotelStartPay_model.dart';

class AkHotelStartPayRepositoryImpl implements AkHotelStartPayRepository {
  final AkHotelStartPayApiService apiService;

  AkHotelStartPayRepositoryImpl(this.apiService);

  @override
  Future<DataState<AkHotelStartPayEntity>> startPay(AkHotelStartPayRequestEntity request) async {
    try {
      // Sent as a number when parseable — Benzy's own example shows a bare
      // integer literal for TransactionID, not a quoted string.
      final numericId = int.tryParse(request.transactionId);
      final body = {
        'TransactionID': numericId ?? request.transactionId,
        'NetAmount': request.netAmount,
        'PaymentAmount': request.paymentAmount,
        'payment_reference': request.paymentReference,
        'gateway': request.gateway,
        'DepositPayment': true,
        'OnlinePayment': false,
        'search_tracing_key': request.searchTracingKey,
      };

      final response = await apiService.startPay(body);
      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return DataSuccess(AkHotelStartPayModel.fromJson(data));
      }

      // 503 (kill-switch off) / 402 (payment not verified) / other errors
      // all come back as {"success": false, "error": "..."} — surface that
      // message rather than a generic failure.
      final errorMessage = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Failed to confirm the booking (status ${response.statusCode})';

      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/start-pay/'),
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
          message: errorMessage,
        ),
      );
    } on DioException catch (e) {
      print('Start Pay Repository Error: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('Start Pay Repository Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: '/api/akbar-hotels/start-pay/'),
          error: e.toString(),
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
