import '../../domain/entity/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.balance,
    required super.currency,
    required super.isActive,
    required super.notifyLowBalance,
    required super.notifyTransactions,
    required super.lowBalanceThreshold,
    required super.created,
    required super.updated,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] ?? 0,
      balance: json['balance']?.toString() ?? '0.00',
      currency: json['currency'] ?? 'INR',
      isActive: json['is_active'] ?? false,
      notifyLowBalance: json['notify_low_balance'] ?? false,
      notifyTransactions: json['notify_transactions'] ?? false,
      lowBalanceThreshold: json['low_balance_threshold']?.toString() ?? '0.00',
      created: json['created'] ?? '',
      updated: json['updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balance': balance,
      'currency': currency,
      'is_active': isActive,
      'notify_low_balance': notifyLowBalance,
      'notify_transactions': notifyTransactions,
      'low_balance_threshold': lowBalanceThreshold,
      'created': created,
      'updated': updated,
    };
  }
}

// Model for the full API response (includes total_earnings at root level)
class WalletResponseModel {
  final bool success;
  final WalletModel wallet;
  final String totalEarnings;

  WalletResponseModel({
    required this.success,
    required this.wallet,
    required this.totalEarnings,
  });

  factory WalletResponseModel.fromJson(Map<String, dynamic> json) {
    return WalletResponseModel(
      success: json['success'] ?? false,
      wallet: WalletModel.fromJson(json['wallet'] ?? {}),
      totalEarnings: json['total_earnings']?.toString() ?? '0',
    );
  }
}