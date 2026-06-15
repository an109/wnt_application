import 'package:dio/dio.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/transaction_entity.dart';
import '../../domain/repository/transaction_repository.dart';
import '../data_source/transaction_api_service.dart';
import '../model/transacction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionApiService _apiService;

  TransactionRepositoryImpl(this._apiService);

  @override
  Future<DataState<TransactionsResponseEntity>> getTransactions({
    String? type,
    int? days,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.getTransactions(
        type: type,
        days: days,
        search: search,
        page: page,
        pageSize: pageSize,
      );

      final responseModel = TransactionsResponseModel.fromJson(response.data);
      return DataSuccess(responseModel);
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}