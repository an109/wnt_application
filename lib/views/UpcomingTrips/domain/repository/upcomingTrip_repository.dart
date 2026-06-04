import '../../../../core/error/data_state.dart';
import '../entity/upcomingTrip_entity.dart';

abstract class UpcomingTripRepository {
  Future<DataState<List<UpcomingTripEntity>>> getUpcomingTrips({
    required String userEmail,
  });
}