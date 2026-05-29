import 'package:equatable/equatable.dart';
import '../../domain/entity/wallet_entity.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final WalletEntity wallet;

  const WalletLoaded({required this.wallet});

  String get balance => wallet.balance;
  String get currency => wallet.currency;
  String get totalEarnings => wallet.totalEarnings;
  bool get isActive => wallet.isActive;
  String get lowBalanceThreshold => wallet.lowBalanceThreshold;

  @override
  List<Object?> get props => [wallet];
}

class WalletError extends WalletState {
  final String message;

  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}