import '../../../../core/error/data_state.dart';
import '../entity/poll_entity.dart';
import '../repository/poll_repository.dart';

class GetReservationPollUseCase {
  final ReservationPollRepository repository;

  GetReservationPollUseCase(this.repository);

  Future<DataState<ReservationPollEntity>> call({required String searchId}) async {
    return await repository.getReservationPoll(searchId: searchId);
  }
}