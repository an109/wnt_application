import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/T_SearchUsecase.dart';
import 'T_SearchEvent.dart';
import 'T_SearchState.dart';

class TransportSearchBloc
    extends Bloc<TransportSearchEvent, TransportSearchState> {
  final TransportSearchUsecase transportSearchUsecase;

  TransportSearchBloc({required this.transportSearchUsecase})
      : super(const TransportSearchInitial()) {
    on<SearchTransport>(_onSearchTransport);
    on<ClearTransportSearch>(_onClearTransportSearch);
  }

  Future<void> _onSearchTransport(
      SearchTransport event,
      Emitter<TransportSearchState> emit,
      ) async {
    print('DEBUG BLOC: _onSearchTransport called');
    print('DEBUG BLOC: Event params - start: ${event.startAddress}, mode: ${event.modeValue}');

    emit(const TransportSearchLoading());

    print('DEBUG BLOC: Calling usecase...');
    final result = await transportSearchUsecase.execute(
      startAddress: event.startAddress,
      endAddress: event.endAddress,
      pickupDatetime: event.pickupDatetime,
      numPassengers: event.numPassengers,
      currency: event.currency,
      mode: event.modeValue,
    );
    print('DEBUG BLOC: Usecase returned: ${result.runtimeType}');

    if (result is DataSuccess) {
      print('DEBUG BLOC: Emitting TransportSearchSuccess');
      emit(TransportSearchSuccess(result.data!));
    } else if (result is DataFailed) {
      print('DEBUG BLOC: Emitting TransportSearchFailed - error: ${result.error?.message}');
      emit(TransportSearchFailed(result));
    }
  }

  Future<void> _onClearTransportSearch(
      ClearTransportSearch event,
      Emitter<TransportSearchState> emit,
      ) async {
    emit(const TransportSearchInitial());
  }
}