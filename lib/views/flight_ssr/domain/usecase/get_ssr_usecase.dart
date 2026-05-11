import '../../../../core/error/data_state.dart';
import '../entities/ssr_entity.dart';
import '../repository/ssr_repository.dart';

class GetSsrUsecase {
  final SsrRepository repository;

  GetSsrUsecase(this.repository);

  Future<DataState<SsrEntity>> call({
    required String endUserIp,
    required String traceId,
    required String tokenId,
    required String resultIndex,
  }) {
    return repository.getSsrData(
      endUserIp: endUserIp,
      traceId: traceId,
      tokenId: tokenId,
      resultIndex: resultIndex,
    );
  }
}