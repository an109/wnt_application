import '../../../../core/error/data_state.dart';
import '../entity/transaction_entity.dart';

abstract class TransactionRepository {
  Future<DataState<TransactionsResponseEntity>> getTransactions({
    String? type,
    int? days,
    String? search,
    int page,
    int pageSize,
  });
}