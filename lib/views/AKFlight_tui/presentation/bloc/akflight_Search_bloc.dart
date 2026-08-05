import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/data_state.dart';
import '../../domain/usecase/akflight_search_usecase.dart';
import 'akflight_Search_event.dart';
import 'akflight_Search_state.dart';


class AkFlightSearchBloc extends Bloc<AkFlightSearchEvent, AkFlightSearchState> {
  final AkFlightSearchUseCase flightSearchUseCase;

  AkFlightSearchBloc(this.flightSearchUseCase) : super(const AkFlightSearchInitial()) {
    on<AkFlightSearchInitEvent>(_onInit);
    on<AkFlightSearchExecuteEvent>(_onExecuteSearch);
    on<AkFlightSearchResetEvent>(_onReset);
  }

  Future<void> _onInit(
      AkFlightSearchInitEvent event,
      Emitter<AkFlightSearchState> emit,
      ) async {
    emit(const AkFlightSearchInitial());
  }

  Future<void> _onExecuteSearch(
      AkFlightSearchExecuteEvent event,
      Emitter<AkFlightSearchState> emit,
      ) async {
    emit(const AkFlightSearchLoading());

    final result = await flightSearchUseCase(event.request);

    emit(AkFlightSearchDataState(result));

    if (result is DataSuccess) {
      emit(AkFlightSearchSuccess(result.data!));
    } else if (result is DataFailed) {
      final errorMessage = result.error?.message ?? 'An unknown error occurred';
      emit(AkFlightSearchFailed(errorMessage));
    }
  }

  Future<void> _onReset(
      AkFlightSearchResetEvent event,
      Emitter<AkFlightSearchState> emit,
      ) async {
    emit(const AkFlightSearchInitial());
  }
}