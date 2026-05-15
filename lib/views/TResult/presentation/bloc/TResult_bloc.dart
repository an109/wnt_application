import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/get_TResult_usecase.dart';
import 'TResult_event.dart';
import 'TResult_state.dart';

class TransportResultBloc
    extends Bloc<TransportResultEvent, TransportResultState> {
  final GetTransportResultUseCase getTransportResultUseCase;

  TransportResultBloc({required this.getTransportResultUseCase})
      : super(const TransportResultInitial()) {
    on<GetTransportResultEvent>(_onGetTransportResult);
  }

  Future<void> _onGetTransportResult(
      GetTransportResultEvent event,
      Emitter<TransportResultState> emit,
      ) async {
    print('Fetching transport result for searchId: ${event.searchId}, resultId: ${event.resultId}');

    emit(const TransportResultLoading());

    final result = await getTransportResultUseCase(
      searchId: event.searchId,
      resultId: event.resultId,
    );

    print('Transport result fetch completed with status: ${result.runtimeType}');

    if (result is DataSuccess) {
      print('Transport result fetched successfully');
      emit(TransportResultSuccess(result.data!));
    } else if (result is DataFailed) {
      print('Transport result fetch failed: ${result.error?.message}');
      emit(TransportResultFailure(result));
    }
  }
}