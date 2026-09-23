import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/TPollSearchEntity.dart';
import '../../domain/usecase/TPoll_search_usecase.dart';
import 'TPoll_SearchEvent.dart';
import 'TPoll_SearchState.dart';

/// Polls the transport search until the supplier says it's done.
///
/// The poll endpoint answers immediately with whatever has arrived so far —
/// usually `results: []` + `more_coming: true` on the first call, because the
/// supplier (Mozio) is still searching. So a single fetch isn't enough: keep
/// polling every [pollInterval] while `more_coming` is true, emitting each
/// snapshot so rides appear as they arrive.
class TpollSearchBloc extends Bloc<TpollSearchEvent, TpollSearchState> {
  final TpollSearchUseCase tpollSearchUseCase;
  final Duration pollInterval;
  final int maxPolls;

  /// Bumped on every (re)start so an older polling loop stops itself.
  int _generation = 0;

  TpollSearchBloc({
    required this.tpollSearchUseCase,
    this.pollInterval = const Duration(seconds: 3),
    this.maxPolls = 40, // ~2 minutes at the default interval
  }) : super(const TpollSearchInitial()) {
    on<TpollSearchFetchEvent>((e, emit) => _pollUntilDone(e.searchId, emit));
    on<TpollSearchRefreshEvent>((e, emit) => _pollUntilDone(e.searchId, emit));
  }

  Future<void> _pollUntilDone(
    String searchId,
    Emitter<TpollSearchState> emit,
  ) async {
    final generation = ++_generation;
    bool cancelled() => generation != _generation || isClosed || emit.isDone;

    emit(const TpollSearchLoading());

    TpollSearchEntity? latest;
    var consecutiveFailures = 0;

    for (var poll = 0; poll < maxPolls; poll++) {
      final result = await tpollSearchUseCase(searchId);
      if (cancelled()) return;

      if (result is DataSuccess<TpollSearchEntity>) {
        consecutiveFailures = 0;
        latest = result.data!;
        emit(TpollSearchSuccess(tpollSearchEntity: latest));
        if (!latest.search.moreComing) return; // supplier finished
      } else if (result is DataFailed<TpollSearchEntity>) {
        // Nothing to show yet → surface the error like before.
        if (latest == null) {
          emit(TpollSearchFailure(error: result.error!));
          return;
        }
        // Otherwise tolerate a blip; give up after a few in a row.
        if (++consecutiveFailures >= 3) break;
      }

      await Future.delayed(pollInterval);
      if (cancelled()) return;
    }

    // Gave up polling (max polls or repeated failures) while the supplier was
    // still "more_coming": settle on what we have so the UI stops spinning
    // and shows either the rides or a real empty state.
    if (latest != null && latest.search.moreComing) {
      emit(TpollSearchSuccess(tpollSearchEntity: latest.copyWith(moreComing: false)));
    }
  }
}
