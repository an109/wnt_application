import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../../domain/entity/transaction_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionSuccess extends TransactionState {
  final TransactionsResponseEntity data;
  final bool hasMore;

  const TransactionSuccess({required this.data, required this.hasMore});

  @override
  List<Object?> get props => [data, hasMore];
}

class TransactionFailed extends TransactionState {
  final DioException error;

  const TransactionFailed({required this.error});

  @override
  List<Object?> get props => [error];
}