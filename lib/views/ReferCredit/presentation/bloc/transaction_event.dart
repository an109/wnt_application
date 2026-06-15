import 'package:equatable/equatable.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class FetchTransactions extends TransactionEvent {
  final String? type;
  final int? days;
  final String? search;
  final int page;
  final int pageSize;
  final bool loadMore;

  const FetchTransactions({
    this.type,
    this.days,
    this.search,
    this.page = 1,
    this.pageSize = 20,
    this.loadMore = false,
  });

  @override
  List<Object?> get props => [type, days, search, page, pageSize, loadMore];
}