import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/views/TReservation_poll/presentation/bloc/poll_event.dart';
import 'package:wander_nova/views/TReservation_poll/presentation/bloc/poll_state.dart';
import '../../domain/usecase/get_poll_usecase.dart';
import '../../../../core/error/data_state.dart';


class ReservationPollBloc extends Bloc<ReservationPollEvent, ReservationPollState> {
  final GetReservationPollUseCase _getReservationPollUseCase;

  ReservationPollBloc(this._getReservationPollUseCase) : super(ReservationPollInitial()) {
    on<FetchReservationPoll>(_onFetchReservationPoll);
  }

  Future<void> _onFetchReservationPoll(
      FetchReservationPoll event,
      Emitter<ReservationPollState> emit,
      ) async {
    emit(ReservationPollLoading());
    print('Fetching reservation poll for searchId: ${event.searchId}');

    final dataState = await _getReservationPollUseCase(searchId: event.searchId);

    if (dataState is DataSuccess) {
      print('Reservation poll fetched successfully');
      emit(ReservationPollSuccess(dataState.data!));
    } else if (dataState is DataFailed) {
      print('Reservation poll fetch failed: ${dataState.error?.message}');
      emit(ReservationPollFailed(dataState.error?.message ?? 'Unknown error'));
    }
  }
}