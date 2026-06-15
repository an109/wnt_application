
import '../../domain/entity/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.transactionType,
    required super.amount,
    required super.description,
    required super.status,
    required super.reference,
    required super.paymentMethod,
    required super.created,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      transactionType: json['transaction_type'] ?? '',
      amount: json['amount'] ?? '0.00',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      reference: json['reference'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      created: json['created'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_type': transactionType,
      'amount': amount,
      'description': description,
      'status': status,
      'reference': reference,
      'payment_method': paymentMethod,
      'created': created,
    };
  }
}

class TransactionsResponseModel extends TransactionsResponseEntity {
  const TransactionsResponseModel({
    required super.success,
    required super.transactions,
    required super.total,
    required super.page,
    required super.pageSize,
    required super.hasMore,
  });

  factory TransactionsResponseModel.fromJson(Map<String, dynamic> json) {
    return TransactionsResponseModel(
      success: json['success'] ?? false,
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((e) => TransactionModel.fromJson(e))
          .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      hasMore: json['has_more'] ?? false,
    );
  }
}