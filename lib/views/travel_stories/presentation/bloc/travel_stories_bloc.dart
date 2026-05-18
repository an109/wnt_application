import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/get_travel_stories_by_slug_usecase.dart';
import '../../domain/usecase/get_travel_stories_usecase.dart';
import 'travel_stories_event.dart';
import 'travel_stories_state.dart';

class TravelStoriesBloc extends Bloc<TravelStoriesEvent, TravelStoriesState> {
  final GetTravelStoriesUseCase getTravelStoriesUseCase;
  final GetTravelStoryBySlugUseCase getTravelStoryBySlugUseCase;

  TravelStoriesBloc({
    required this.getTravelStoriesUseCase,
    required this.getTravelStoryBySlugUseCase,
  }) : super(const TravelStoriesInitial()) {
    on<GetTravelStoriesEvent>(_onGetTravelStories);
    on<GetTravelStoryBySlugEvent>(_onGetTravelStoryBySlug);
    on<RefreshTravelStoriesEvent>(_onRefreshTravelStories);
  }

  Future<void> _onGetTravelStories(
      GetTravelStoriesEvent event,
      Emitter<TravelStoriesState> emit,
      ) async {
    emit(const TravelStoriesLoading());

    final dataState = await getTravelStoriesUseCase(
      status: event.status,
      domain: event.domain,
      limit: event.limit,
    );

    if (dataState is DataSuccess && dataState.data != null) {
      emit(TravelStoriesLoaded(
        stories: dataState.data!,
        count: dataState.data!.length,
      ));
    }
    if (dataState is DataFailed && dataState.error != null) {
      emit(TravelStoriesError(
        dataState.error!.message ?? 'Failed to load travel stories',
      ));
    }
  }

  Future<void> _onGetTravelStoryBySlug(
      GetTravelStoryBySlugEvent event,
      Emitter<TravelStoriesState> emit,
      ) async {
    emit(const TravelStoriesLoading());

    final dataState = await getTravelStoryBySlugUseCase(event.slug);

    if (dataState is DataSuccess && dataState.data != null) {
      emit(TravelStoryDetailLoaded(dataState.data!));
    }
    if (dataState is DataFailed && dataState.error != null) {
      emit(TravelStoriesError(
        dataState.error!.message ?? 'Failed to load travel story',
      ));
    }
  }

  Future<void> _onRefreshTravelStories(
      RefreshTravelStoriesEvent event,
      Emitter<TravelStoriesState> emit,
      ) async {
    // You can add refresh logic here if needed
    add(const GetTravelStoriesEvent(
      status: 'published',
      domain: 'thewandernova.com',
      limit: 8,
    ));
  }
}