import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKSsr_usecase.dart';
import 'AKSsr_event.dart';
import 'AKSsr_state.dart';

class AkSsrBloc extends Bloc<AkSsrEvent, AkSsrState> {
  final AkSsrUseCase ssrUseCase;

  AkSsrBloc(this.ssrUseCase) : super(const AkSsrInitial()) {
    on<LoadAkSsrEvent>(_onLoad);
    on<ResetAkSsrEvent>(_onReset);
  }

  Future<void> _onLoad(LoadAkSsrEvent event, Emitter<AkSsrState> emit) async {
    emit(const AkSsrLoading());

    final result = await ssrUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkSsrLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkSsrFailed(error: result.error!));
    }
  }

  Future<void> _onReset(ResetAkSsrEvent event, Emitter<AkSsrState> emit) async {
    emit(const AkSsrInitial());
  }
}
