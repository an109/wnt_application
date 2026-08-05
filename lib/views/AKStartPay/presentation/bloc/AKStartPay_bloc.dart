import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKStartPay_usecase.dart';
import 'AKStartPay_event.dart';
import 'AKStartPay_state.dart';

class AkStartPayBloc extends Bloc<AkStartPayEvent, AkStartPayState> {
  final AkStartPayUseCase startPayUseCase;

  AkStartPayBloc(this.startPayUseCase) : super(const AkStartPayInitial()) {
    on<LoadAkStartPayEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadAkStartPayEvent event,
      Emitter<AkStartPayState> emit,
      ) async {
    emit(const AkStartPayLoading());

    final result = await startPayUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkStartPayLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkStartPayFailed(error: result.error!));
    }
  }
}
