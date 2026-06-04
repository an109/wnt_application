import '../../../../core/error/data_state.dart';
import '../entity/upcomingTrip_entity.dart';
import '../repository/upcomingTrip_repository.dart';

class GetUpcomingTripsUseCase {
  final UpcomingTripRepository repository;

  GetUpcomingTripsUseCase(this.repository);

  Future<DataState<List<UpcomingTripEntity>>> call({
    required String userEmail,
  }) async {
    return await repository.getUpcomingTrips(userEmail: userEmail);
  }
}