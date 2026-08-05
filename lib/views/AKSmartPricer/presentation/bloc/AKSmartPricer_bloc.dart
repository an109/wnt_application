import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKSmartPricer_usecase.dart';
import 'AKSmartPricer_event.dart';
import 'AKSmartPricer_state.dart';

class AkSmartPricerBloc extends Bloc<AkSmartPricerEvent, AkSmartPricerState> {
  final AkSmartPricerUseCase smartPricerUseCase;

  AkSmartPricerBloc(this.smartPricerUseCase) : super(const AkSmartPricerInitial()) {
    on<LoadAkSmartPricerEvent>(_onLoad);
    on<ResetAkSmartPricerEvent>(_onReset);
  }

  Future<void> _onLoad(
      LoadAkSmartPricerEvent event,
      Emitter<AkSmartPricerState> emit,
      ) async {
    emit(const AkSmartPricerLoading());

    final result = await smartPricerUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkSmartPricerLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkSmartPricerFailed(error: result.error!));
    }
  }

  Future<void> _onReset(
      ResetAkSmartPricerEvent event,
      Emitter<AkSmartPricerState> emit,
      ) async {
    emit(const AkSmartPricerInitial());
  }
}
