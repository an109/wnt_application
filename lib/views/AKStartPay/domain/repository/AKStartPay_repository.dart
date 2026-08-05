import '../../../../core/error/data_state.dart';
import '../entity/AKStartPay_entity.dart';

abstract class AkStartPayRepository {
  Future<DataState<AkStartPayEntity>> startPay(AkStartPayRequestEntity request);
}
