import '../../../../core/error/data_state.dart';
import '../entity/AKSelectSeats_entity.dart';

abstract class AkSelectSeatsRepository {
  Future<DataState<AkSelectSeatsEntity>> selectSeats(AkSelectSeatsRequestEntity request);
}
