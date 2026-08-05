import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/AKRetrieveBooking_usecase.dart';
import 'AKRetrieveBooking_event.dart';
import 'AKRetrieveBooking_state.dart';

class AkRetrieveBookingBloc extends Bloc<AkRetrieveBookingEvent, AkRetrieveBookingState> {
  final AkRetrieveBookingUseCase retrieveBookingUseCase;

  AkRetrieveBookingBloc(this.retrieveBookingUseCase) : super(const AkRetrieveBookingInitial()) {
    on<LoadAkRetrieveBookingEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadAkRetrieveBookingEvent event,
      Emitter<AkRetrieveBookingState> emit,
      ) async {
    emit(const AkRetrieveBookingLoading());

    final result = await retrieveBookingUseCase.call(event.request);

    if (result is DataSuccess) {
      emit(AkRetrieveBookingLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(AkRetrieveBookingFailed(error: result.error!));
    }
  }
}
