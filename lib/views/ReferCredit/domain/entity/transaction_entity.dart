import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final int id;
  final String transactionType;
  final String amount;
  final String description;
  final String status;
  final String reference;
  final String paymentMethod;
  final String created;

  const TransactionEntity({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.description,
    required this.status,
    required this.reference,
    required this.paymentMethod,
    required this.created,
  });

  @override
  List<Object?> get props => [
    id, transactionType, amount, description, status,
    reference, paymentMethod, created,
  ];
}

class TransactionsResponseEntity extends Equatable {
  final bool success;
  final List<TransactionEntity> transactions;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const TransactionsResponseEntity({
    required this.success,
    required this.transactions,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [success, transactions, total, page, pageSize, hasMore];
}