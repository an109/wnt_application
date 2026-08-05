import '../../../../core/error/data_state.dart';
import '../entity/AKFlightInfo_entity.dart';

abstract class AkFlightInfoRepository {
  Future<DataState<AkFlightInfoEntity>> getFlightInfo(
      AkFlightInfoRequestEntity request);
}
