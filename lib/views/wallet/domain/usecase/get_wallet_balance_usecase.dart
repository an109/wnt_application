import '../../../../core/error/data_state.dart';
import '../entity/wallet_entity.dart';
import '../repository/wallet_repository.dart';

class GetWalletBalanceUseCase {
  final WalletRepository repository;

  GetWalletBalanceUseCase(this.repository);

  Future<DataState<WalletEntity>> call() async {
    return await repository.getWalletBalance();
  }
}