import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKFlightInfo_usecase.dart';
import 'AKFlightInfo_event.dart';
import 'AKFlightInfo_state.dart';

class AkFlightInfoBloc extends Bloc<AkFlightInfoEvent, AkFlightInfoState> {
  final AkFlightInfoUseCase flightInfoUseCase;

  AkFlightInfoBloc(this.flightInfoUseCase) : super(const AkFlightInfoInitial()) {
    on<LoadAkFlightInfoEvent>(_onLoad);
    on<ResetAkFlightInfoEvent>(_onReset);
  }

  Future<void> _onLoad(
      LoadAkFlightInfoEvent event,
      Emitter<AkFlightInfoState> emit,
      ) async {
    emit(const AkFlightInfoLoading());

    final result = await flightInfoUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkFlightInfoLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkFlightInfoFailed(error: result.error!));
    }
  }

  Future<void> _onReset(
      ResetAkFlightInfoEvent event,
      Emitter<AkFlightInfoState> emit,
      ) async {
    emit(const AkFlightInfoInitial());
  }
}
