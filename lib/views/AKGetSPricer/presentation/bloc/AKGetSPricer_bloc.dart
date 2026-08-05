import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKGetSPricer_usecase.dart';
import 'AKGetSPricer_event.dart';
import 'AKGetSPricer_state.dart';

class AkGetSPricerBloc extends Bloc<AkGetSPricerEvent, AkGetSPricerState> {
  final AkGetSPricerUseCase getSPricerUseCase;

  AkGetSPricerBloc(this.getSPricerUseCase) : super(const AkGetSPricerInitial()) {
    on<LoadAkGetSPricerEvent>(_onLoad);
    on<ResetAkGetSPricerEvent>(_onReset);
  }

  Future<void> _onLoad(
      LoadAkGetSPricerEvent event,
      Emitter<AkGetSPricerState> emit,
      ) async {
    emit(const AkGetSPricerLoading());

    final result = await getSPricerUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkGetSPricerLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkGetSPricerFailed(error: result.error!));
    }
  }

  Future<void> _onReset(
      ResetAkGetSPricerEvent event,
      Emitter<AkGetSPricerState> emit,
      ) async {
    emit(const AkGetSPricerInitial());
  }
}
