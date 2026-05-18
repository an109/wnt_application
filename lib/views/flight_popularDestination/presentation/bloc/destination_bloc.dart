import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_popular_destination_usecase.dart';
import 'destination_event.dart';
import 'destination_state.dart';

class PopularDestinationBloc extends Bloc<PopularDestinationEvent, PopularDestinationState> {
  final GetPopularDestinationsUseCase getPopularDestinationsUseCase;

  PopularDestinationBloc({
    required this.getPopularDestinationsUseCase,
  }) : super(const PopularDestinationInitial()) {
    on<FetchPopularDestinations>(_onFetchPopularDestinations);
  }

  Future<void> _onFetchPopularDestinations(
      FetchPopularDestinations event,
      Emitter<PopularDestinationState> emit,
      ) async {
    emit(const PopularDestinationLoading());

    final result = await getPopularDestinationsUseCase();

    if (result.data != null) {
      emit(PopularDestinationLoaded(result.data!));
    } else if (result.error != null) {
      emit(PopularDestinationError(
        result.error?.message ?? 'Failed to fetch destinations',
      ));
    }
  }
}