import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/transaction_entity.dart';
import '../../domain/usecase/get_transaction_usecase.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsUseCase _getTransactionsUseCase;

  TransactionBloc({required GetTransactionsUseCase getTransactionsUseCase})
      : _getTransactionsUseCase = getTransactionsUseCase,
        super(TransactionInitial()) {
    on<FetchTransactions>(_onFetchTransactions);
  }

  Future<void> _onFetchTransactions(
      FetchTransactions event,
      Emitter<TransactionState> emit,
      ) async {
    if (!event.loadMore) {
      emit(TransactionLoading());
    }

    final dataState = await _getTransactionsUseCase(
      type: event.type,
      days: event.days,
      search: event.search,
      page: event.page,
      pageSize: event.pageSize,
    );

    // Utilizing your provided DataState classes
    if (dataState is DataSuccess<TransactionsResponseEntity>) {
      emit(TransactionSuccess(
        data: dataState.data!,
        hasMore: dataState.data!.hasMore,
      ));
    } else if (dataState is DataFailed<TransactionsResponseEntity>) {
      emit(TransactionFailed(error: dataState.error!));
    }
  }
}