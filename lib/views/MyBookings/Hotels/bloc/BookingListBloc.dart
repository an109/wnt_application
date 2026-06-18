import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/data_state.dart';
import '../domain/usecase/getHotelBookingUsecase.dart';
import 'BookingListEvent.dart';
import 'BookingListState.dart';


class HotelBookingListBloc extends Bloc<HotelEvent, HotelState> {
  final GetHotelBookingsUseCase _getHotelBookingsUseCase;

  HotelBookingListBloc(this._getHotelBookingsUseCase) : super(HotelInitial()) {
    on<FetchHotelBookings>(_onFetchHotelBookings);
  }

  Future<void> _onFetchHotelBookings(
      FetchHotelBookings event,
      Emitter<HotelState> emit,
      ) async {
    emit(HotelLoading());

    print('HotelBookingListBloc: Fetching hotel bookings...');

    final dataState = await _getHotelBookingsUseCase();

    if (dataState is DataSuccess && dataState.data!.isNotEmpty) {
      print('HotelBookingListBloc: Hotel bookings fetched successfully. Count: ${dataState.data!.length}');
      emit(HotelLoaded(dataState.data!));
    } else if (dataState is DataSuccess && dataState.data!.isEmpty) {
      print('HotelBookingListBloc: No hotel bookings found.');
      emit(const HotelLoaded([]));
    } else if (dataState is DataFailed) {
      print('HotelBookingListBloc: Error fetching hotel bookings. Error: ${dataState.error?.message}');
      emit(HotelError(dataState.error?.message ?? dataState.error?.error?.toString() ?? 'An unknown error occurred'));
    } else {
      emit(const HotelError('Failed to fetch hotel bookings'));
    }
  }
}