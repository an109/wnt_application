import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/wallet_entity.dart';
import '../../domain/repository/wallet_repository.dart';
import '../data_source/wallet_api_service.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletApiService walletApiService;

  WalletRepositoryImpl(this.walletApiService);

  @override
  Future<DataState<WalletEntity>> getWalletBalance() async {
    try {
      final response = await walletApiService.getWalletBalance();

      print('WALLET API Response Status: ${response.statusCode}');
      print('WALLET API Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true && data['wallet'] != null) {
          final walletModel = WalletModel.fromJson(data['wallet']);
          final totalEarnings = data['total_earnings']?.toString() ?? '0';

          final walletEntity = WalletEntity(
            id: walletModel.id,
            balance: walletModel.balance,
            currency: walletModel.currency,
            isActive: walletModel.isActive,
            notifyLowBalance: walletModel.notifyLowBalance,
            notifyTransactions: walletModel.notifyTransactions,
            lowBalanceThreshold: walletModel.lowBalanceThreshold,
            created: walletModel.created,
            updated: walletModel.updated,
            totalEarnings: totalEarnings,
          );

          print('WALLET Balance fetched: ${walletEntity.balance} ${walletEntity.currency}');
          return DataSuccess(walletEntity);
        } else {
          print('WALLET API: Invalid response format - success: ${data['success']}');
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Invalid response format from server',
              type: DioExceptionType.badResponse,
              response: response,
            ),
          );
        }
      } else {
        print('WALLET API: Failed with status ${response.statusCode}');
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Failed to fetch wallet balance',
            type: DioExceptionType.badResponse,
            response: response,
          ),
        );
      }
    } on DioException catch (e) {
      print('WALLET API DioException: ${e.message}');
      print('WALLET API Error Response: ${e.response?.data}');
      final serverError = _extractError(e);
      return DataFailed(
        DioException(
          requestOptions: e.requestOptions,
          error: serverError,
          type: e.type,
          response: e.response,
        ),
      );
    } catch (e) {
      print('WALLET API Unknown Error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Something went wrong. Please try again.',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['error'] ?? data['message'] ?? data['detail'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    final status = e.response?.statusCode;
    if (status == 401) return 'Please sign in to access your wallet.';
    if (status == 403) return 'You do not have permission to access this.';
    if (status != null && status >= 500) return 'Server error. Please try again later.';
    return 'Could not load wallet. Please try again.';
  }
}