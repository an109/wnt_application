import '../../../../core/error/data_state.dart';
import '../entities/fare_quote_entity.dart';

abstract class FareQuoteRepository {
  Future<DataState<FareQuoteEntity>> getFareQuote({
    required String endUserIp,
    required String traceId,
    required String tokenId,
    required String resultIndex,
  });
}