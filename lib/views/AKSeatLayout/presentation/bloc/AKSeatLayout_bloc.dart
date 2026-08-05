import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKSeatLayout_usecase.dart';
import 'AKSeatLayout_event.dart';
import 'AKSeatLayout_state.dart';

class AkSeatLayoutBloc extends Bloc<AkSeatLayoutEvent, AkSeatLayoutState> {
  final AkSeatLayoutUseCase seatLayoutUseCase;

  AkSeatLayoutBloc(this.seatLayoutUseCase) : super(const AkSeatLayoutInitial()) {
    on<LoadAkSeatLayoutEvent>(_onLoad);
    on<ResetAkSeatLayoutEvent>(_onReset);
  }

  Future<void> _onLoad(
    LoadAkSeatLayoutEvent event,
    Emitter<AkSeatLayoutState> emit,
  ) async {
    emit(const AkSeatLayoutLoading());

    final result = await seatLayoutUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkSeatLayoutLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkSeatLayoutFailed(error: result.error!));
    }
  }

  Future<void> _onReset(
    ResetAkSeatLayoutEvent event,
    Emitter<AkSeatLayoutState> emit,
  ) async {
    emit(const AkSeatLayoutInitial());
  }
}
