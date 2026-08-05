import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entity/AKFlights_entity.dart';
import '../../domain/usecase/AKFlights_usecase.dart';
import 'AKFlights_event.dart';
import 'AKFlights_state.dart';

class AkflightsBloc extends Bloc<AkflightsEvent, AkflightsState> {
  final GetAkflightsUseCase getAkflightsUseCase;
  Timer? _pollingTimer;

  // The tui the bloc is currently polling for. Guards against a response
  // for an older/cancelled search landing after a newer LoadAkflightsEvent
  // has already started (e.g. the user picked a different date), and stops
  // the previous poll chain from scheduling any further requests.
  String? _activeTui;

  AkflightsBloc({required this.getAkflightsUseCase})
      : super(const AkflightsInitial()) {
    on<LoadAkflightsEvent>(_onLoadAkflights);
    on<PollAkflightsEvent>(_onPollAkflights);
    on<ResetAkflightsEvent>(_onResetAkflights);
  }

  Future<void> _onLoadAkflights(
      LoadAkflightsEvent event,
      Emitter<AkflightsState> emit,
      ) async {
    _stopPolling();
    _activeTui = event.tui;
    emit(const AkflightsLoading());

    final result = await getAkflightsUseCase.call(tui: event.tui);
    if (_activeTui != event.tui) return; // superseded while awaiting

    _handleResult(result, event.tui, emit);
  }

  Future<void> _onPollAkflights(
      PollAkflightsEvent event,
      Emitter<AkflightsState> emit,
      ) async {
    if (_activeTui != event.tui) return; // stale poll, search moved on

    final result = await getAkflightsUseCase.call(tui: event.tui);
    if (_activeTui != event.tui) return; // superseded while awaiting

    _handleResult(result, event.tui, emit);
  }

  void _handleResult(DataState<AkflightsSearchEntity> result, String tui,
      Emitter<AkflightsState> emit) {
    if (result is DataSuccess) {
      final data = result.data!;

      // Every poll's Trips list is emitted as-is — per the API contract the
      // results only grow across polls, so each response already includes
      // everything gathered so far. Emitting here (instead of only once
      // Completed) lets the UI render flights the moment the first poll has
      // any, rather than waiting for the whole search to finish.
      emit(AkflightsSuccess(
        akflightsData: data,
        isCompleted: data.completed,
      ));

      if (data.completed) {
        _stopPolling();
      } else {
        // Only schedule the next poll once this one has fully resolved,
        // instead of firing on a fixed interval regardless of how long the
        // in-flight request takes — the previous Timer.periodic approach
        // could stack up several overlapping requests for a slow poll,
        // whose out-of-order responses flickered the UI between states.
        _scheduleNextPoll(tui);
      }
    } else if (result is DataFailed) {
      emit(AkflightsFailed(error: result.error!));
      _stopPolling();
    }
  }

  Future<void> _onResetAkflights(
      ResetAkflightsEvent event,
      Emitter<AkflightsState> emit,
      ) async {
    _stopPolling();
    emit(const AkflightsInitial());
  }

  void _scheduleNextPoll(String tui) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer(const Duration(seconds: 1), () {
      if (_activeTui == tui) add(PollAkflightsEvent(tui: tui));
    });
  }

  void _stopPolling() {
    _activeTui = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
