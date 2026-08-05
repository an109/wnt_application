import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKCreateItinerary_usecase.dart';
import 'AKCreateItinerary_event.dart';
import 'AKCreateItinerary_state.dart';

class AkCreateItineraryBloc extends Bloc<AkCreateItineraryEvent, AkCreateItineraryState> {
  final AkCreateItineraryUseCase createItineraryUseCase;

  AkCreateItineraryBloc(this.createItineraryUseCase) : super(const AkCreateItineraryInitial()) {
    on<LoadAkCreateItineraryEvent>(_onLoad);
    on<ResetAkCreateItineraryEvent>(_onReset);
  }

  Future<void> _onLoad(
      LoadAkCreateItineraryEvent event,
      Emitter<AkCreateItineraryState> emit,
      ) async {
    emit(const AkCreateItineraryLoading());

    final result = await createItineraryUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkCreateItineraryLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkCreateItineraryFailed(error: result.error!));
    }
  }

  Future<void> _onReset(
      ResetAkCreateItineraryEvent event,
      Emitter<AkCreateItineraryState> emit,
      ) async {
    emit(const AkCreateItineraryInitial());
  }
}
