import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final int id;
  final String balance;
  final String currency;
  final bool isActive;
  final bool notifyLowBalance;
  final bool notifyTransactions;
  final String lowBalanceThreshold;
  final String created;
  final String updated;
  final String totalEarnings;

  const WalletEntity({
    required this.id,
    required this.balance,
    required this.currency,
    required this.isActive,
    required this.notifyLowBalance,
    required this.notifyTransactions,
    required this.lowBalanceThreshold,
    required this.created,
    required this.updated,
    this.totalEarnings = '0',
  });

  @override
  List<Object?> get props => [
    id,
    balance,
    currency,
    isActive,
    notifyLowBalance,
    notifyTransactions,
    lowBalanceThreshold,
    created,
    updated,
    totalEarnings,
  ];
}