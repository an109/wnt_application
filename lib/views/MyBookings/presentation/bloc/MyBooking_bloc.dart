import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/views/MyBookings/domain/usecase/get_bookings_usecase.dart';
import '../../../../core/error/data_state.dart';
import 'MyBooking_event.dart';
import 'MyBooking_state.dart';


class MyBookingBloc extends Bloc<BookingEvent, BookingState> {
  final GetBookingsUseCase _getBookingsUseCase;

  MyBookingBloc(this._getBookingsUseCase) : super(BookingInitial()) {
    on<FetchBookings>(_onFetchBookings);
  }

  Future<void> _onFetchBookings(
      FetchBookings event,
      Emitter<BookingState> emit,
      ) async {
    emit(BookingLoading());

    print('MyBookingBloc: Fetching bookings...');

    final dataState = await _getBookingsUseCase();

    if (dataState is DataSuccess && dataState.data!.isNotEmpty) {
      print('MyBookingBloc: Bookings fetched successfully. Count: ${dataState.data!.length}');
      emit(BookingLoaded(dataState.data!));
    } else if (dataState is DataSuccess && dataState.data!.isEmpty) {
      print('MyBookingBloc: No bookings found.');
      emit(const BookingLoaded([]));
    } else if (dataState is DataFailed) {
      print('MyBookingBloc: Error fetching bookings. Error: ${dataState.error?.message}');
      emit(BookingError(dataState.error?.message ?? dataState.error?.error?.toString() ?? 'An unknown error occurred'));
    } else {
      emit(const BookingError('Failed to fetch bookings'));
    }
  }
}