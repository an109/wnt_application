import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

/// Outcome of [WalletApiService.payBooking].
class WalletDebit {
  final bool success;

  /// The wallet transaction's reference for this debit.
  final String? reference;
  final String? error;

  const WalletDebit({required this.success, this.reference, this.error});
}

abstract class WalletApiService {
  Future<Response> getWalletBalance();

  /// Deducts [amount] (INR) from the wallet for a booking via
  /// /wallet/pay-booking/ — the same call the website makes before StartPay /
  /// creating the reservation, whose payment guards look for this debit
  /// against [bookingRef]. [bookingType]: flight, hotel, transport, holiday.
  Future<WalletDebit> payBooking({
    required double amount,
    required String bookingType,
    required String bookingRef,
    required String description,
  });
}

class WalletApiServiceImpl implements WalletApiService {
  final Dio dio;

  WalletApiServiceImpl(this.dio);

  @override
  Future<Response> getWalletBalance() async {
    try {
      print('CALLING WALLET BALANCE API: ${Urls.walletBalance}');

      final response = await dio.get(Urls.walletBalance);

      print('WALLET BALANCE RESPONSE: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('WALLET API Error: ${e.message}');
      print('WALLET API Error Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('WALLET Unknown Error: $e');
      throw DioException(
        requestOptions: RequestOptions(path: Urls.walletBalance),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  @override
  Future<WalletDebit> payBooking({
    required double amount,
    required String bookingType,
    required String bookingRef,
    required String description,
  }) async {
    try {
      final response = await dio.post(
        Urls.walletPayBooking,
        data: {
          'amount': amount,
          'booking_type': bookingType,
          'booking_ref': bookingRef,
          'description': description,
        },
      );
      final data = response.data is Map ? response.data as Map : const {};
      return WalletDebit(
        success: data['success'] == true,
        reference: data['reference']?.toString(),
        error: data['error']?.toString(),
      );
    } on DioException catch (e) {
      print('WALLET PAY-BOOKING Error: ${e.message}');
      print('WALLET PAY-BOOKING Error Response: ${e.response?.data}');
      final data = e.response?.data;
      return WalletDebit(
        success: false,
        error: data is Map ? data['error']?.toString() : null,
      );
    }
  }
}
