import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/views/UpcomingTrips/presentation/bloc/upcomingTrip_event.dart';
import 'package:wander_nova/views/UpcomingTrips/presentation/bloc/upcomingTrip_state.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/upcomingTrip_entity.dart';
import '../../domain/usecase/get_upcomingTrip_usecase.dart';

class UpcomingTripBloc extends Bloc<UpcomingTripEvent, UpcomingTripState> {
  final GetUpcomingTripsUseCase getUpcomingTripsUseCase;

  UpcomingTripBloc({required this.getUpcomingTripsUseCase})
      : super(UpcomingTripInitial()) {
    on<FetchUpcomingTrips>(_onFetchUpcomingTrips);
  }

  Future<void> _onFetchUpcomingTrips(
      FetchUpcomingTrips event,
      Emitter<UpcomingTripState> emit,
      ) async {
    emit(UpcomingTripLoading());
    print('Fetching upcoming trips for user: ${event.userEmail}');

    final dataState = await getUpcomingTripsUseCase.call(
      userEmail: event.userEmail,
    );

    if (dataState is DataSuccess<List>) {
      final trips = List<UpcomingTripEntity>.from(dataState.data as List);

      print('Emitting ${trips.length} trips to state');
      emit(UpcomingTripLoaded(trips));
    } else if (dataState is DataFailed) {
      print('Emitting error state: ${dataState.error?.message}');
      emit(UpcomingTripError(dataState.error!));
    }
  }
}