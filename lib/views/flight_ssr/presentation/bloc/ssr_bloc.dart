import 'package:bloc/bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/ssr_entity.dart';
import '../../domain/usecase/get_ssr_usecase.dart';
import 'ssr_event.dart';
import 'ssr_state.dart';

class SsrBloc extends Bloc<SsrEvent, SsrState> {
  final GetSsrUsecase getSsrUsecase;

  SsrBloc({required this.getSsrUsecase}) : super(SsrInitial()) {
    on<LoadSsrData>(_onLoadSsrData);
  }

  Future<void> _onLoadSsrData(
      LoadSsrData event,
      Emitter<SsrState> emit,
      ) async {
    emit(SsrLoading());

    print('SsrBloc: Loading SSR data with TraceId: ${event.traceId}');

    final result = await getSsrUsecase(
      endUserIp: event.endUserIp,
      traceId: event.traceId,
      tokenId: event.tokenId,
      resultIndex: event.resultIndex,
    );

    print('SsrBloc: API call completed');

    if (result is DataSuccess<SsrEntity>) {
      print('SsrBloc: Data loaded successfully');
      emit(SsrLoaded(result.data!));
    } else if (result is DataFailed<SsrEntity>) {
      final errorMessage = result.error?.message ?? 'Unknown error occurred';
      print('SsrBloc: Error - $errorMessage');
      emit(SsrError(errorMessage));
    }
  }
}