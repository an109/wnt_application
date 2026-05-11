import '../../../../core/error/data_state.dart';
import '../../domain/entities/fare_quote_entity.dart';
import '../../domain/repository/fare_quote_repository.dart';

class FareQuoteUsecase {
  final FareQuoteRepository repository;

  FareQuoteUsecase(this.repository);

  Future<DataState<FareQuoteEntity>> call({
    required String endUserIp,
    required String traceId,
    required String tokenId,
    required String resultIndex,
  }) {
    return repository.getFareQuote(
      endUserIp: endUserIp,
      traceId: traceId,
      tokenId: tokenId,
      resultIndex: resultIndex,
    );
  }
}