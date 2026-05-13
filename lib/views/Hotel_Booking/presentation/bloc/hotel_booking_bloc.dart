import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/get_hotel_booking_details_usecase.dart';
import 'hotel_booking_event.dart';
import 'hotel_booking_state.dart';

class HotelBookingBloc extends Bloc<HotelBookingEvent, HotelBookingState> {
  final GetHotelBookingDetailsUseCase getHotelBookingDetailsUseCase;

  HotelBookingBloc({
    required this.getHotelBookingDetailsUseCase,
  }) : super(const HotelBookingInitial()) {
    on<GetHotelBookingDetailsEvent>(_onGetHotelBookingDetails);
  }

  Future<void> _onGetHotelBookingDetails(
      GetHotelBookingDetailsEvent event,
      Emitter<HotelBookingState> emit,
      ) async {
    emit(const HotelBookingLoading());

    final result = await getHotelBookingDetailsUseCase(
      bookingCode: event.bookingCode,
      paymentMode: event.paymentMode,
    );

    if (result is DataSuccess) {
      emit(HotelBookingLoaded(result.data!));
    } else if (result is DataFailed) {
      final errorMessage = result.error?.response?.data?['message'] ??
          result.error?.message ??
          'An unexpected error occurred';
      emit(HotelBookingError(errorMessage));
    }
  }
}