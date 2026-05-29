import '../../../../core/error/data_state.dart';
import '../entity/wallet_entity.dart';

abstract class WalletRepository {
  Future<DataState<WalletEntity>> getWalletBalance();
}