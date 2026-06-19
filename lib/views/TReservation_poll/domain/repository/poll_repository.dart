import '../../../../core/error/data_state.dart';
import '../entity/poll_entity.dart';

abstract class ReservationPollRepository {
  Future<DataState<ReservationPollEntity>> getReservationPoll({required String searchId});
}