import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class FetchWalletBalance extends WalletEvent {
  const FetchWalletBalance();
}

class RefreshWalletBalance extends WalletEvent {
  const RefreshWalletBalance();
}