import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/TPollSearchEntity.dart';
import '../../domain/usecase/TPoll_search_usecase.dart';
import 'TPoll_SearchEvent.dart';
import 'TPoll_SearchState.dart';

class TpollSearchBloc extends Bloc<TpollSearchEvent, TpollSearchState> {
  final TpollSearchUseCase tpollSearchUseCase;

  TpollSearchBloc({required this.tpollSearchUseCase})
      : super(const TpollSearchInitial()) {
    on<TpollSearchFetchEvent>(_onFetchSearch);
    on<TpollSearchRefreshEvent>(_onRefreshSearch);
  }

  Future<void> _onFetchSearch(
      TpollSearchFetchEvent event,
      Emitter<TpollSearchState> emit,
      ) async {
    emit(const TpollSearchLoading());

    final result = await tpollSearchUseCase(event.searchId);

    if (result is DataSuccess<TpollSearchEntity>) {
      emit(TpollSearchSuccess(tpollSearchEntity: result.data!));
    } else if (result is DataFailed<TpollSearchEntity>) {
      emit(TpollSearchFailure(error: result.error!));
    }
  }

  Future<void> _onRefreshSearch(
      TpollSearchRefreshEvent event,
      Emitter<TpollSearchState> emit,
      ) async {
    emit(const TpollSearchLoading());

    final result = await tpollSearchUseCase(event.searchId);

    if (result is DataSuccess<TpollSearchEntity>) {
      emit(TpollSearchSuccess(tpollSearchEntity: result.data!));
    } else if (result is DataFailed<TpollSearchEntity>) {
      emit(TpollSearchFailure(error: result.error!));
    }
  }
}