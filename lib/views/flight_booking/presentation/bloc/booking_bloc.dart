import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/book_flight_usecase.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookFlightUsecase bookFlightUsecase;

  BookingBloc({required this.bookFlightUsecase}) : super(BookingInitial()) {
    on<BookFlightEvent>(_onBookFlight);
  }

  Future<void> _onBookFlight(
    BookFlightEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    final result = await bookFlightUsecase(event.request);
    if (result is DataSuccess) {
      emit(BookingSuccess(result.data!));
    } else if (result is DataFailed) {
      emit(BookingError(result.error?.message ?? 'Booking failed'));
    }
  }
}
