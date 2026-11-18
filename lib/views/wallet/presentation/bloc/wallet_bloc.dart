import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/wallet_entity.dart';
import '../../domain/usecase/get_wallet_balance_usecase.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final GetWalletBalanceUseCase getWalletBalanceUseCase;

  WalletBloc({required this.getWalletBalanceUseCase}) : super(const WalletInitial()) {
    on<FetchWalletBalance>(_onFetchWalletBalance);
    on<RefreshWalletBalance>(_onRefreshWalletBalance);
  }

  Future<void> _onFetchWalletBalance(
      FetchWalletBalance event,
      Emitter<WalletState> emit,
      ) async {
    print('WALLET BLOC: FetchWalletBalance event triggered');
    emit(const WalletLoading());

    final result = await getWalletBalanceUseCase();

    if (result is DataSuccess<WalletEntity>) {
      print('WALLET BLOC: DataSuccess received');
      emit(WalletLoaded(wallet: result.data!));
    } else if (result is DataFailed<WalletEntity>) {
      final raw = result.error;
      final errorMessage = (raw?.error is String && (raw!.error as String).isNotEmpty)
          ? raw.error as String
          : 'Could not load wallet. Please try again.';
      print('WALLET BLOC: DataFailed - $errorMessage');
      emit(WalletError(message: errorMessage));
    }
  }

  Future<void> _onRefreshWalletBalance(
      RefreshWalletBalance event,
      Emitter<WalletState> emit,
      ) async {
    print('WALLET BLOC: RefreshWalletBalance event triggered');
    await _onFetchWalletBalance(const FetchWalletBalance(), emit);
  }
}