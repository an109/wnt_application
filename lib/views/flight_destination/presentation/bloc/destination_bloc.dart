import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/search_destination_usecase.dart';
import 'destination_event.dart';
import 'destination_state.dart';

class DestinationBloc extends Bloc<DestinationEvent, DestinationState> {
  final SearchDestinationsUseCase searchDestinationsUseCase;

  DestinationBloc({required this.searchDestinationsUseCase})
      : super(const DestinationInitial()) {
    on<LoadDestinationsEvent>(_onLoadDestinations);
    on<SearchDestinationsEvent>(_onSearchDestinations);
  }

  FutureOr<void> _onLoadDestinations(
      LoadDestinationsEvent event,
      Emitter<DestinationState> emit,
      ) async {
    emit(const DestinationLoading());

    final result = await searchDestinationsUseCase.execute(
      query: event.searchQuery ?? '',
      countryCode: event.countryCode,
    );

    if (result is DataSuccess) {
      emit(DestinationLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(DestinationError(result.error?.message ?? 'An error occurred'));
    }
  }

  FutureOr<void> _onSearchDestinations(
      SearchDestinationsEvent event,
      Emitter<DestinationState> emit,
      ) async {
    // Always emit loading first
    emit(const DestinationLoading());

    final result = await searchDestinationsUseCase.execute(
      query: event.query,
      countryCode: event.countryCode,
      limit: event.limit,
    );

    if (result is DataSuccess) {
      // Make sure destinationData is not null
      emit(DestinationLoaded(result.data!));
    } else if (result is DataFailed) {
      emit(DestinationError(result.error?.message ?? 'Search failed'));
    }
  }
}