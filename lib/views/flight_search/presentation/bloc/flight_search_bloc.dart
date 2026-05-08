import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/entities/flight_entity.dart';
import '../../domain/usecase/flight_search_usecase.dart';
import 'flight_search_event.dart';
import 'flight_search_state.dart';

class FlightSearchBloc extends Bloc<FlightSearchEvent, FlightSearchState> {
  final SearchFlightsUseCase searchFlightsUseCase;

  FlightSearchBloc(this.searchFlightsUseCase) : super(FlightSearchInitial()) {
    on<SearchFlightsEvent>(_onSearchFlights);
    on<ClearFlightsEvent>(_onClearFlights);
  }

  Future<void> _onSearchFlights(
      SearchFlightsEvent event,
      Emitter<FlightSearchState> emit,
      ) async {
    emit(FlightSearchLoading());

    try {
      final result = await searchFlightsUseCase.call(event.request);

      if (result is DataSuccess<List<FlightEntity>>) {
        final flights = result.data ?? [];
        emit(FlightSearchLoaded(
          flights: flights,
          traceId: null, // Will be populated from response if needed
          origin: event.request.segments.first.origin,
          destination: event.request.segments.first.destination,
        ));
      } else if (result is DataFailed) {
        final errorMessage = result.error?.message ?? 'Failed to search flights';
        emit(FlightSearchError(errorMessage));
      }
    } catch (e) {
      emit(FlightSearchError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  void _onClearFlights(
      ClearFlightsEvent event,
      Emitter<FlightSearchState> emit,
      ) {
    emit(FlightSearchInitial());
  }
}