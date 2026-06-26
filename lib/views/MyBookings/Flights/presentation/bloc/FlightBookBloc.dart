import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/data_state.dart';
import '../../domain/usecase/GetFlightBookUsecase.dart';
import 'FlightBookEvent.dart';
import 'FlightBookState.dart';


class FlightBookBloc extends Bloc<FlightBookEvent, FlightBookState> {
  final GetBookUseCase getFlightBookingsUseCase;

  FlightBookBloc(this.getFlightBookingsUseCase)
      : super(const FlightBookInitial()) {
    on<FetchFlightBookings>(_onFetchFlightBookings);
    on<RefreshFlightBookings>(_onRefreshFlightBookings);
  }

  Future<void> _onFetchFlightBookings(
      FetchFlightBookings event,
      Emitter<FlightBookState> emit,
      ) async {
    print('FlightBookBloc: Fetching flight bookings');
    emit(const FlightBookLoading());

    final result = await getFlightBookingsUseCase(userId: event.userId);

    if (result is DataSuccess) {
      print('FlightBookBloc: Successfully loaded ${result.data?.length} bookings');
      emit(FlightBookLoaded(result.data!));
    } else if (result is DataFailed) {
      print('FlightBookBloc: Failed to load bookings');
      emit(FlightBookError(result.error!));
    }
  }

  Future<void> _onRefreshFlightBookings(
      RefreshFlightBookings event,
      Emitter<FlightBookState> emit,
      ) async {
    print('FlightBookBloc: Refreshing flight bookings');
    emit(const FlightBookLoading());

    final result = await getFlightBookingsUseCase(userId: event.userId);

    if (result is DataSuccess) {
      emit(FlightBookLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(FlightBookError(result.error!));
    }
  }
}