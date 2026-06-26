import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/booking_details_service.dart';
import 'booking_details_event.dart';
import 'booking_details_state.dart';

class BookingDetailsBloc
    extends Bloc<BookingDetailsEvent, BookingDetailsState> {
  final BookingDetailsService service;

  BookingDetailsBloc({required this.service}) : super(BookingDetailsInitial()) {
    on<FetchBookingDetailsEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    emit(BookingDetailsLoading());
    final result = await service.fetch(event.pnr);
    if (result.isSuccess) {
      emit(BookingDetailsLoaded(result));
    } else {
      emit(BookingDetailsError(
          result.errorMessage ?? 'Failed to load booking details'));
    }
  }
}
