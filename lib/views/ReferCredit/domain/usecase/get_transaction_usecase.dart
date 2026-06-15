import '../../../../core/error/data_state.dart';
import '../../domain/repository/transaction_repository.dart';
import '../entity/transaction_entity.dart';

class GetTransactionsUseCase {
  final TransactionRepository _repository;

  GetTransactionsUseCase(this._repository);

  Future<DataState<TransactionsResponseEntity>> call({
    String? type,
    int? days,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getTransactions(
      type: type,
      days: days,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }
}