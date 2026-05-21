import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/get_detination_usecase.dart';
import 'holiday_destination_event.dart';
import 'holiday_destination_state.dart';


class HolidayBloc extends Bloc<HolidayEvent, HolidayState> {
  final GetDestinationsUseCase getPopularDestinationsUseCase;

  HolidayBloc({required this.getPopularDestinationsUseCase})
      : super(const HolidayInitialState()) {
    on<GetPopularDestinationsEvent>(_onGetPopularDestinations);
  }

  Future<void> _onGetPopularDestinations(
      GetPopularDestinationsEvent event,
      Emitter<HolidayState> emit,
      ) async {
    emit(const HolidayLoadingState());

    final result = await getPopularDestinationsUseCase();

    if (result is DataSuccess) {
      emit(HolidaySuccessState(result.data!));
    } else if (result is DataFailed) {
      emit(HolidayErrorState(
        result.error?.message ?? 'Failed to fetch destinations',
      ));
    }
  }
}