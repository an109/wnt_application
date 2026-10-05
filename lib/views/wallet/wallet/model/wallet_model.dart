enum TransactionType { all, credit, debit }

enum TimeFilter { allTime, last3Days, last7Days, last30Days }

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

  /// The gateway's own reference for the charge, shown on the transaction
  /// card so a traveller can quote it to support. Empty when the backend did
  /// not send one, and the card then omits the line rather than printing an
  /// empty reference.
  final String reference;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isCredit,
    this.status = 'Completed',
    this.reference = '',
  });

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  /// Thousands-separated, no trailing paise — the form the balance card and
  /// the transaction rows use.
  String get compactAmount {
    final whole = amount.abs().round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '₹${buf.toString()}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// `14 May 2026, 02:57 pm` — the absolute stamp the design prints under the
  /// description. [formattedDate] stays as it was for anything still showing
  /// the relative form.
  String get formattedDateTime {
    final h24 = date.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final mm = date.minute.toString().padLeft(2, '0');
    final suffix = h24 < 12 ? 'am' : 'pm';
    return '${date.day} ${_months[date.month - 1]} ${date.year}, '
        '${h12.toString().padLeft(2, '0')}:$mm $suffix';
  }

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