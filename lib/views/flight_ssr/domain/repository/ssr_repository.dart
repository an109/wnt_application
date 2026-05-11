import '../../../../core/error/data_state.dart';
import '../entities/ssr_entity.dart';

abstract class SsrRepository {
  Future<DataState<SsrEntity>> getSsrData({
    required String endUserIp,
    required String traceId,
    required String tokenId,
    required String resultIndex,
  });
}