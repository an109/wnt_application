enum TransactionType { all, credit, debit }

enum TimeFilter { allTime, last7Days, last30Days }

class WalletBalance {
  final double balance;
  final double totalEarnings;
  final String currency;

  const WalletBalance({
    required this.balance,
    required this.totalEarnings,
    this.currency = '₹',
  });

  WalletBalance copyWith({
    double? balance,
    double? totalEarnings,
    String? currency,
  }) {
    return WalletBalance(
      balance: balance ?? this.balance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currency: currency ?? this.currency,
    );
  }
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final bool isCredit;
  final String status;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isCredit,
    this.status = 'Completed',
  });

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class NotificationSettings {
  bool lowBalanceAlert;
  bool transactionAlerts;
  double? lowBalanceThreshold;

  NotificationSettings({
    this.lowBalanceAlert = false,
    this.transactionAlerts = true,
    this.lowBalanceThreshold,
  });
}