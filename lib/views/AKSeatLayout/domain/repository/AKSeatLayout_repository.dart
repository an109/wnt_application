import '../../../../core/error/data_state.dart';
import '../entity/AKSeatLayout_entity.dart';

abstract class AkSeatLayoutRepository {
  Future<DataState<AkSeatLayoutEntity>> getSeatLayout(AkSeatLayoutRequestEntity request);
}
