import 'package:dio/dio.dart';
import '../../../../core/constants/urls.dart';

abstract class WalletApiService {
  Future<Response> getWalletBalance();
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
}