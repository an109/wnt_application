import '../../../../injection_container.dart';
import '../../domain/entity/wallet_entity.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

class WalletService {
  late final WalletBloc _bloc;

  WalletService() {
    _bloc = sl<WalletBloc>();
  }

  Stream<WalletState> get stateStream => _bloc.stream;

  WalletState get currentState => _bloc.state;

  void fetchBalance() {
    print('WALLET SERVICE: fetchBalance called');
    _bloc.add(const FetchWalletBalance());
  }

  void refreshBalance() {
    print('WALLET SERVICE: refreshBalance called');
    _bloc.add(const RefreshWalletBalance());
  }

  void dispose() {
    _bloc.close();
  }

  // Helper to get current wallet data if loaded
  WalletEntity? getWalletData() {
    final state = _bloc.state;
    if (state is WalletLoaded) {
      return state.wallet;
    }
    return null;
  }
}